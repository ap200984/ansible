#!/usr/bin/env python3
"""Send generated fixtures over actual TCP streams; assert parsed JSON documents."""

import datetime
import json
from pathlib import Path
import subprocess
import sys
import time


def docker_stream(container, port, payload):
    return subprocess.run(
        ["docker", "exec", "-i", container, "bash", "-c",
         f"cat > /dev/tcp/127.0.0.1/{port}"],
        input=payload, text=True, capture_output=True, timeout=10,
    )


def field(event, path):
    value = event
    for key in path.split("."):
        assert isinstance(value, dict) and key in value, f"Missing {path!r} in {event!r}"
        value = value[key]
    return value


def expect(event, path, expected):
    actual = field(event, path)
    assert actual == expected, f"{path}: expected {expected!r}, got {actual!r} in {event!r}"


def main():
    container, output = sys.argv[1:]
    year = datetime.datetime.now(datetime.timezone.utc).year
    fixtures = [
        ("linux_iso", "/var/log/auth.log", "2026-10-17T12:34:56+00:00 fixture-host sshd[1234]: Accepted publickey for fixture-user from 192.0.2.10 port 54321 ssh2: RSA fixture-key"),
        ("linux_bsd", "/var/log/syslog", "Oct 17 12:35:56 fixture-host CRON[2345]: fixture-linux-bsd"),
        ("linux_dpkg", "/var/log/dpkg.log", "2026-10-17 12:36:56 status installed rsyslog:amd64 8.2302.0-1"),
        ("linux_apt_date", "/var/log/apt/history.log", "Start-Date: 2026-10-17  12:37:56"),
        ("linux_apt_command", "/var/log/apt/history.log", "Commandline: apt-get install rsyslog"),
        ("linux_apt_term", "/var/log/apt/term.log", "Log started: 2026-10-17  12:38:56"),
        ("linux_generic", "/var/log/cloud-init-output.log", "fixture-cloud-init text"),
        ("linux_invalid", "/var/log/auth.log", "fixture malformed syslog record"),
        ("linux_escaped", "/var/log/cloud-init-output.log", 'fixture newline\nquote="hello" backslash=\\'),
        ("linux_cloudinit", "/var/log/cloud-init.log", "2026-10-17 12:39:56,123 - util.py[DEBUG]: fixture-cloudinit-parsed"),
        ("linux_alternatives", "/var/log/alternatives.log", "update-alternatives 2026-10-17 12:40:56: fixture-alternatives-parsed"),
    ]
    linux = []
    for identity, path, message in fixtures:
        linux.append({
            "fixture_id": identity, "log_source": "linux",
            "@timestamp": "2026-10-17T12:00:00.000Z", "message": message,
            "host": {"name": "fixture-vds"}, "log": {"file": {"path": path}},
            "event": {"module": "system", "dataset": "system.fixture"},
        })
    # The first CEF fixture follows MikroTik's documented observed message format.
    # Both frames share one TCP stream, covering the newline codec delimiter.
    cef = [
        "Oct 17 15:40:56 MikroTik CEF:0|MikroTik|hAP ax^2|7.24.5|10|system,error,critical|High|dvchost=MikroTik dvc=192.168.88.36 msg=mikrotik:K16_112: fixture-cef-bsd app=ssh duser=guest outcome=failure src=192.168.88.17",
        "<30>2026-10-17T15:41:56+03:00 fixture-router CEF:0|MikroTik|hAP ax^3|7.24.5|11|system,warning|Medium|dvchost=fixture-router dvc=10.255.0.24 msg=mikrotik:Misha: fixture-cef-iso src=10.0.0.10 dst=10.0.0.20 spt=12345 dpt=443 proto=TCP",
    ]
    deadline = time.monotonic() + 180
    for port in (10514, 5514):
        while time.monotonic() < deadline:
            result = docker_stream(container, port, "")
            if result.returncode == 0:
                break
            time.sleep(2)
        else:
            raise AssertionError(f"Isolated Logstash TCP input {port} did not become ready")

    for port, payload in [(10514, "".join(json.dumps(x) + "\n" for x in linux)),
                          (5514, "\n".join(cef) + "\n")]:
        result = docker_stream(container, port, payload)
        assert result.returncode == 0, f"TCP fixture sender failed: {result.stderr}"

    events = []
    deadline = time.monotonic() + 45
    while time.monotonic() < deadline:
        try:
            events = [json.loads(line) for line in Path(output).read_text().splitlines() if line]
        except (FileNotFoundError, json.JSONDecodeError):
            time.sleep(1)
            continue
        if len(events) >= len(linux) + len(cef):
            break
        time.sleep(1)
    assert len(events) == len(linux) + len(cef), f"Expected {len(linux) + len(cef)} framed events; received {len(events)}: {events!r}"
    by_id = {event["fixture_id"]: event for event in events if "fixture_id" in event}
    for identity, path, original in fixtures:
        event = by_id[identity]
        expect(event, "host.name", "fixture-vds")
        expect(event, "log.file.path", path)
        expect(event, "event.original", original)
        expect(event, "fixture_target_index", "linux-logs")
        assert "log_source" not in event, event
        failures = [tag for tag in event.get("tags", []) if "failure" in tag]
        assert failures == (["_linux_syslogparsefailure"] if identity == "linux_invalid" else []), event
    expect(by_id["linux_iso"], "process.pid", 1234)
    expect(by_id["linux_iso"], "process.name", "sshd")
    expect(by_id["linux_iso"], "host.hostname", "fixture-host")
    expect(by_id["linux_iso"], "message", "Accepted publickey for fixture-user from 192.0.2.10 port 54321 ssh2: RSA fixture-key")
    expect(by_id["linux_iso"], "event.outcome", "success")
    expect(by_id["linux_iso"], "event.action", "ssh_login")
    expect(by_id["linux_iso"], "user.name", "fixture-user")
    expect(by_id["linux_iso"], "source.ip", "192.0.2.10")
    expect(by_id["linux_iso"], "source.port", 54321)
    expect(by_id["linux_iso"], "system.auth.ssh.method", "publickey")
    expect(by_id["linux_iso"], "@timestamp", "2026-10-17T12:34:56.000Z")
    expect(by_id["linux_bsd"], "@timestamp", f"{year}-10-17T12:35:56.000Z")
    expect(by_id["linux_dpkg"], "dpkg.action", "status")
    expect(by_id["linux_dpkg"], "@timestamp", "2026-10-17T12:36:56.000Z")
    expect(by_id["linux_apt_date"], "apt.operation", "Start-Date")
    expect(by_id["linux_apt_date"], "@timestamp", "2026-10-17T12:37:56.000Z")
    expect(by_id["linux_apt_command"], "apt.operation", "Commandline")
    expect(by_id["linux_apt_command"], "@timestamp", "2026-10-17T12:00:00.000Z")
    expect(by_id["linux_apt_term"], "@timestamp", "2026-10-17T12:38:56.000Z")
    expect(by_id["linux_generic"], "message", "fixture-cloud-init text")
    expect(by_id["linux_escaped"], "message", fixtures[8][2])
    expect(by_id["linux_cloudinit"], "message", "fixture-cloudinit-parsed")
    expect(by_id["linux_cloudinit"], "log.level", "debug")
    expect(by_id["linux_cloudinit"], "log.logger", "util.py")
    expect(by_id["linux_cloudinit"], "@timestamp", "2026-10-17T12:39:56.123Z")
    expect(by_id["linux_alternatives"], "message", "fixture-alternatives-parsed")
    expect(by_id["linux_alternatives"], "process.name", "update-alternatives")
    expect(by_id["linux_alternatives"], "@timestamp", "2026-10-17T12:40:56.000Z")

    routers = {event["host"]["name"]: event for event in events if event.get("event", {}).get("module") == "routeros"}
    assert set(routers) == {"K16_112", "Misha"}, routers
    for router, event in routers.items():
        expect(event, "fixture_target_index", "mikrotik-logs")
        expect(event, "observer.type", "router")
        assert isinstance(field(event, "event.severity"), int), event
        assert not [tag for tag in event.get("tags", []) if "failure" in tag], event
        assert "CEF:0|MikroTik|" in field(event, "event.original"), event
    expect(routers["K16_112"], "message", "fixture-cef-bsd")
    expect(routers["K16_112"], "event.severity", 8)
    expect(routers["K16_112"], "log.level", "critical")
    expect(routers["K16_112"], "source.ip", "192.168.88.17")
    expect(routers["K16_112"], "host.ip", "192.168.88.36")
    expect(routers["K16_112"], "@timestamp", f"{year}-10-17T15:40:56.000Z")
    expect(routers["Misha"], "message", "fixture-cef-iso")
    expect(routers["Misha"], "event.severity", 5)
    expect(routers["Misha"], "log.level", "warning")
    expect(routers["Misha"], "source.port", 12345)
    expect(routers["Misha"], "destination.port", 443)
    expect(routers["Misha"], "network.transport", "tcp")
    expect(routers["Misha"], "@timestamp", "2026-10-17T12:41:56.000Z")
    print("PASS: 13 TCP-framed events; Linux ISO/BSD, SSH auth fields, dpkg, apt, cloud-init, alternatives, raw text, JSON escaping, expected malformed-syslog tagging; RouterOS CEF named severity, ECS addresses/ports, identity and timezone parsing.")


if __name__ == "__main__":
    main()
