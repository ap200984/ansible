#!/usr/bin/env python3
"""Read Deye SG01LP1 dashboard metrics using read-only Modbus TCP FC03.

Zabbix external check: deye_modbus_metrics.py[host,port,unit]
Port defaults to 502 and unit defaults to 1. The register map is for the
SG01LP1 low-voltage single-phase family, including SUN-8K-SG01LP1-EU.
JSON values are under ``metrics``; ``units`` describes their engineering units.
"""

import argparse
import datetime as dt
import json
import math
import re
import socket
import struct
import sys
from pathlib import Path


class ModbusError(Exception):
    """An incomplete or invalid Modbus response."""


READ_BLOCKS = ((26, 34), (70, 43), (150, 45))


def validate_connection(host, port, unit, timeout):
    if not isinstance(host, str) or not host or any(c.isspace() for c in host):
        raise ValueError("Host must be a nonempty IP address or hostname without whitespace")
    if not isinstance(port, int) or isinstance(port, bool) or not 1 <= port <= 65535:
        raise ValueError("Port must be 1..65535")
    if not isinstance(unit, int) or isinstance(unit, bool) or not 0 <= unit <= 255:
        raise ValueError("Modbus unit must be 0..255")
    if not math.isfinite(timeout) or timeout <= 0:
        raise ValueError("Timeout must be a finite positive number")


def recv_exact(sock, size):
    result = bytearray()
    while len(result) < size:
        chunk = sock.recv(size - len(result))
        if not chunk:
            raise ModbusError("Connection closed before complete response")
        result.extend(chunk)
    return bytes(result)


def read_block(host, port, unit, start, count, timeout):
    validate_connection(host, port, unit, timeout)
    if not isinstance(count, int) or isinstance(count, bool) or not 1 <= count <= 125:
        raise ValueError("Modbus FC03 count must be 1..125")
    if (not isinstance(start, int) or isinstance(start, bool)
            or not 0 <= start <= 65535 or start + count > 65536):
        raise ValueError("Modbus register range must be within 0..65535")

    transaction_id = (start + count) & 0xffff
    pdu = struct.pack(">BHH", 3, start, count)
    request = struct.pack(">HHHB", transaction_id, 0, len(pdu) + 1, unit) + pdu
    with socket.create_connection((host, port), timeout=timeout) as sock:
        sock.settimeout(timeout)
        sock.sendall(request)
        header = recv_exact(sock, 7)
        tid, protocol, length, response_unit = struct.unpack(">HHHB", header)
        if (tid, protocol, response_unit) != (transaction_id, 0, unit):
            raise ModbusError("Unexpected Modbus TCP response header")
        # At least a function and one data/exception byte, plus the unit byte.
        if not 3 <= length <= 254:
            raise ModbusError(f"Invalid Modbus TCP length: {length}")
        response = recv_exact(sock, length - 1)
        if response[0] == 0x83:
            if len(response) != 2:
                raise ModbusError("Invalid Modbus exception response length")
            raise ModbusError(f"Modbus exception code {response[1]} at register {start}")
        if (response[0] != 3 or response[1] != count * 2
                or len(response) != 2 + count * 2):
            raise ModbusError(f"Invalid response for block {start}..{start + count - 1}")
        values = struct.unpack(">" + "H" * count, response[2:])
        return dict(zip(range(start, start + count), values))


def from_dump(path):
    """Replay an existing zero-based ``mbpoll -0`` register dump offline."""
    result = {}
    for line in Path(path).read_text().splitlines():
        match = re.match(r"^\s*\[(\d+)\]:\s+(-?\d+)\s*$", line)
        if match:
            address, value = map(int, match.groups())
            if not 0 <= address <= 65535 or not 0 <= value <= 65535:
                raise ValueError("Dump addresses and register values must be 0..65535")
            result[address] = value
    if not result:
        raise ValueError("No [address]: value records found in dump")
    return result


def signed16(value):
    return value - 65536 if value >= 32768 else value


def uint32(low, high):
    return low + (high << 16)


# metric key -> (address, type, multiplier, offset, unit)
# Temperatures are encoded as 1000 + temperature*10. The grid purchase
# counter uses registers 78 and 80; register 79 contains grid frequency.
MAP = {
    "RatedPower": (26, "u16", 1, 0, "W"),
    "InverterRunState": (59, "u16", 1, 0, None),
    "DailyChargingEnergy": (70, "u16", .1, 0, "kWh"),
    "DailyDischargingEnergy": (71, "u16", .1, 0, "kWh"),
    "TotalChargeEnergy": (72, "u32", .1, 0, "kWh"),
    "TotalDischargeEnergy": (74, "u32", .1, 0, "kWh"),
    "DailyEnergyPurchased": (76, "u16", .1, 0, "kWh"),
    "DailyGridFeedIn": (77, "u16", .1, 0, "kWh"),
    "CumulativeEnergyPurchased": (78, "u32_grid", .1, 0, "kWh"),
    "GridFrequency": (79, "u16", .01, 0, "Hz"),
    "CumulativeGridFeedIn": (81, "u32", .1, 0, "kWh"),
    "DailyConsumption": (84, "u16", .1, 0, "kWh"),
    "CumulativeConsumption": (85, "u32", .1, 0, "kWh"),
    "DC Temperature": (90, "u16", .1, -100, "°C"),
    "AC Temperature": (91, "u16", .1, -100, "°C"),
    "PVCumulativePowerGenerationActive": (96, "u32", .1, 0, "kWh"),
    "PVDailyPowerGenerationActive": (108, "u16", .1, 0, "kWh"),
    "DCVoltagePV1": (109, "u16", .1, 0, "V"),
    "DCCurrentPV1": (110, "u16", .1, 0, "A"),
    "DCVoltagePV2": (111, "u16", .1, 0, "V"),
    "DCCurrentPV2": (112, "u16", .1, 0, "A"),
    "GridVoltageL1L2": (150, "u16", .1, 0, "V"),
    "GridCurrentL1L2": (160, "u16", .01, 0, "A"),
    "TotalGridPower": (169, "s16", 1, 0, "W"),
    "ExternalCTPowerL1L2": (172, "s16", 1, 0, "W"),
    "InverterOutputPowerL1L2": (175, "s16", 1, 0, "W"),
    "TotalConsumptionPower": (178, "s16", 1, 0, "W"),
    "Temperature- Battery": (182, "u16", .1, -100, "°C"),
    "BatteryVoltage": (183, "u16", .01, 0, "V"),
    "SOC": (184, "u16", 1, 0, "%"),
    "DCPowerPV1": (186, "u16", 1, 0, "W"),
    "DCPowerPV2": (187, "u16", 1, 0, "W"),
    "BatteryPower": (190, "s16", 1, 0, "W"),
    "BatteryCurrent": (191, "s16", .01, 0, "A"),
    "ACOutputFrequencyR": (193, "u16", .01, 0, "Hz"),
    "GridRelayStatus": (194, "u16", 1, 0, None),
}


def decode(registers):
    values = {}
    units = {}
    for key, (address, kind, scale, offset, unit) in MAP.items():
        needed = ([address, 80] if kind == "u32_grid" else
                  [address, address + 1] if kind == "u32" else [address])
        for reg in needed:
            if reg not in registers:
                raise ModbusError(f"Missing register {reg} ({key})")
            if (not isinstance(registers[reg], int) or isinstance(registers[reg], bool)
                    or not 0 <= registers[reg] <= 65535):
                raise ModbusError(f"Invalid unsigned 16-bit value at register {reg}")
        if kind == "u32_grid":
            raw = uint32(registers[address], registers[80])
        elif kind == "u32":
            raw = uint32(registers[address], registers[address + 1])
        elif kind == "s16":
            raw = signed16(registers[address])
        else:
            raw = registers[address]
        number = round(raw * scale + offset, 3)
        values[key] = int(number) if number == int(number) else number
        if unit:
            units[key] = unit
    values["TotalDCInputPower"] = values["DCPowerPV1"] + values["DCPowerPV2"]
    units["TotalDCInputPower"] = "W"
    for alias, source in (
        ("DailyActiveProduction", "PVDailyPowerGenerationActive"),
        ("TotalActiveProduction", "PVCumulativePowerGenerationActive"),
        ("UPSLoadPower", "TotalConsumptionPower"),
    ):
        values[alias] = values[source]
        units[alias] = units[source]
    return values, units


def parse_args(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("host_arg", nargs="?", metavar="HOST")
    parser.add_argument("port_arg", nargs="?", type=int, metavar="PORT")
    parser.add_argument("unit_arg", nargs="?", type=int, metavar="UNIT")
    parser.add_argument("--host", help="Inverter Modbus TCP address")
    parser.add_argument("--port", type=int, help="Modbus TCP port (default: 502)")
    parser.add_argument("--unit", type=int, help="Modbus unit ID (default: 1)")
    parser.add_argument("--timeout", type=float, default=3,
                        help="Socket timeout in seconds per block (default: 3)")
    parser.add_argument("--from-dump", metavar="FILE", help="Decode mbpoll output offline")
    parser.add_argument("--raw", action="store_true", help="Include raw register values")
    parser.add_argument("--pretty", action="store_true", help="Indent JSON for inspection")
    args = parser.parse_args(argv)
    for name, default in (("host", None), ("port", 502), ("unit", 1)):
        positional = getattr(args, name + "_arg")
        named = getattr(args, name)
        if positional is not None and named is not None:
            parser.error(f"Specify {name} either positionally or with --{name}")
        setattr(args, name, named if named is not None else
                positional if positional is not None else default)
    if args.host is None and not args.from_dump:
        parser.error("HOST or --host is required unless --from-dump is used")
    try:
        validate_connection(args.host if args.host is not None else "offline",
                            args.port, args.unit, args.timeout)
    except ValueError as exc:
        parser.error(str(exc))
    return args


def main(argv=None):
    args = parse_args(argv)
    try:
        if args.from_dump:
            registers = from_dump(args.from_dump)
        else:
            registers = {}
            for start, count in READ_BLOCKS:
                registers.update(read_block(args.host, args.port, args.unit,
                                            start, count, args.timeout))
        values, units = decode(registers)
        host = f"[{args.host}]" if args.host and ":" in args.host else args.host
        payload = {
            "timestamp": dt.datetime.now(dt.timezone.utc).isoformat(),
            "source": "offline-mbpoll-dump" if args.from_dump else f"modbus-tcp://{host}:{args.port}",
            "unit_id": args.unit,
            "metrics": values,
            "units": units,
        }
        if args.raw:
            payload["registers"] = {str(k): v for k, v in sorted(registers.items())}
        print(json.dumps(payload, ensure_ascii=False,
                         indent=2 if args.pretty else None,
                         separators=None if args.pretty else (",", ":")))
    except (OSError, ModbusError, ValueError) as exc:
        print(f"Deye Modbus read failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
