#!/usr/bin/env python3
"""Read-only route, ICMP and TCP matrix; emit bounded JSON, never log records."""
import concurrent.futures
import datetime
import ipaddress
import json
import re
import socket
import subprocess
import sys


def private_ip(value):
    address = ipaddress.ip_address(value)
    if address.version != 4 or address not in ipaddress.ip_network("10.0.0.0/8"):
        raise ValueError("Probe addresses must be IPv4 addresses in 10.0.0.0/8")
    return str(address)


def command(arguments, timeout=5):
    try:
        process = subprocess.run(arguments, capture_output=True, text=True, timeout=timeout)
        return process.returncode, process.stdout, process.stderr
    except (OSError, subprocess.TimeoutExpired) as error:
        return -1, "", str(error)


def route(target, source):
    arguments = ["ip", "-j", "-4", "route", "get", target]
    if source:
        arguments += ["from", source]
    rc, stdout, stderr = command(arguments)
    if rc:
        return {"error": stderr.strip()[:240], "rc": rc}
    try:
        rows = json.loads(stdout)
        return {key: value for key, value in rows[0].items()
                if key in ("dev", "gateway", "prefsrc", "src", "from", "table", "type")}
    except (ValueError, IndexError) as error:
        return {"error": str(error)[:240]}


def main():
    config = json.loads(sys.argv[1])
    host = config["host"]
    if not re.fullmatch(r"[A-Za-z0-9_.-]{1,64}", host):
        raise ValueError("Invalid inventory host name")
    targets = config["targets"]
    sources = config["sources"]
    timeout = int(config.get("timeout", 2))
    workers = int(config.get("workers", 8))
    packets = int(config.get("packets", 3))
    if not 1 <= len(targets) <= 64 or not 1 <= len(sources) <= 16:
        raise ValueError("The matrix supports 1..64 targets and 1..16 sources")
    if not 1 <= timeout <= 5 or not 1 <= workers <= 16:
        raise ValueError("Probe timeout must be 1..5 seconds and workers 1..16")
    if not 1 <= packets <= 5:
        raise ValueError("ICMP probes must send 1..5 packets")
    for target in targets:
        target["ip"] = private_ip(target["ip"])
    sources = [None if source == "auto" else private_ip(source) for source in sources]
    if len(set(sources)) != len(sources):
        raise ValueError("Probe source addresses must be unique")
    rc, stdout, stderr = command(["ip", "-j", "-4", "address", "show"])
    if rc:
        raise RuntimeError(stderr[:240])
    local = {entry["local"] for interface in json.loads(stdout)
             for entry in interface.get("addr_info", [])}

    def probe(job):
        source, target = job
        result = {"source": source or "auto", "target": target["ip"],
                  "name": target.get("name", target["ip"]),
                  "required": bool(target.get("required", True)),
                  "route": route(target["ip"], source)}
        if source and source not in local:
            result.update({"ok": False, "error": "source_not_assigned"})
            return result
        arguments = ["ping", "-n", "-c", str(packets), "-i", "0.5", "-W", str(timeout)]
        if source:
            arguments += ["-I", source]
        rc, stdout, stderr = command(arguments + [target["ip"]], timeout=timeout * packets + 2)
        result["ok"] = rc == 0
        counts = re.search(r"(\d+) packets transmitted, (\d+) (?:packets )?received", stdout)
        if counts:
            sent, received = map(int, counts.groups())
            result.update({"sent": sent, "received": received,
                           "packet_loss_percent": round(100 * (sent - received) / sent, 2)})
        if not result["ok"]:
            result["error"] = stderr.strip()[:200] or "no_icmp_reply"
        latency = re.search(r"time[=<]([0-9.]+) ms", stdout)
        if latency:
            result["rtt_ms"] = float(latency.group(1))
        return result

    jobs = [(source, target) for source in sources for target in targets]
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        results = list(pool.map(probe, jobs))
    tcp_results = []
    for check in config.get("tcp_checks", []):
        target = private_ip(check["ip"])
        port = int(check["port"])
        if not 1 <= port <= 65535:
            raise ValueError("Invalid TCP probe port")
        for source in sources:
            item = {"source": source or "auto", "target": target, "port": port}
            try:
                connection = socket.create_connection((target, port), timeout=timeout,
                    source_address=(source, 0) if source else None)
                item.update({"ok": True, "local_address": connection.getsockname()[0]})
                connection.close()
            except OSError as error:
                item.update({"ok": False, "error": str(error)[:200]})
            tcp_results.append(item)
    summary = {}
    for source in sources:
        name = source or "auto"
        rows = [row for row in results if row["source"] == name]
        summary[name] = {"passed": sum(row["ok"] for row in rows),
                         "total": len(rows),
                         "required_failed": [row["target"] for row in rows
                                             if row["required"] and not row["ok"]],
                         "optional_failed": [row["target"] for row in rows
                                             if not row["required"] and not row["ok"]]}
    output = {"host": host,
              "observed_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
              "local_sources": {source or "auto": not source or source in local
                                for source in sources},
              "summary": summary, "icmp": results, "tcp": tcp_results,
              "partial_loss_probes": sum(row["ok"] and row.get("packet_loss_percent", 0) > 0 for row in results),
              "required_failures": sum(row["required"] and not row["ok"] for row in results),
              "tcp_failures": sum(not row["ok"] for row in tcp_results)}
    print(json.dumps(output, sort_keys=True))


if __name__ == "__main__":
    main()
