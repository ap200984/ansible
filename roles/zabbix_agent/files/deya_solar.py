#!/usr/bin/env python3

import argparse
import json
import sys

from pysolarmanv5 import PySolarmanV5


def parse_args():
    parser = argparse.ArgumentParser(
        description="Deye inverter monitoring via Solarman logger"
    )
    parser.add_argument("--ip", required=True, help="Solarman logger IP address")
    parser.add_argument(
        "--port", type=int, default=8899,
        help="Solarman logger TCP port (default: 8899)",
    )
    parser.add_argument(
        "--serial", type=int, required=True,
        help="Solarman logger serial number",
    )
    parser.add_argument(
        "--slave-id", type=int, default=1,
        help="Modbus slave ID (default: 1)",
    )
    return parser.parse_args()


def s16(value):
    """Convert unsigned 16-bit register to signed int16."""
    return value - 65536 if value >= 32768 else value


def u32(low, high):
    """Combine two 16-bit registers, low word first."""
    return low | (high << 16)


def read_metrics(args):
    modbus = PySolarmanV5(
        args.ip, args.serial, port=args.port,
        mb_slave_id=args.slave_id, verbose=False,
    )
    try:
        r90 = modbus.read_holding_registers(90, 22)  # 90..111
        r150 = modbus.read_holding_registers(150, 30)  # 150..179
        r182 = modbus.read_holding_registers(182, 15)  # 182..196
    finally:
        modbus.disconnect()

    def register(addr):
        if 90 <= addr <= 111:
            return r90[addr - 90]
        if 150 <= addr <= 179:
            return r150[addr - 150]
        if 182 <= addr <= 196:
            return r182[addr - 182]
        raise ValueError(f"Register {addr} was not read")

    pv1_power = register(186)
    pv2_power = register(187)
    return {
        "pv": {
            "pv1_voltage": round(register(109) * 0.1, 1),
            "pv1_current": round(register(110) * 0.1, 1),
            "pv1_power": pv1_power,
            "pv2_power": pv2_power,
            "total_power": pv1_power + pv2_power,
            "production_today": round(register(108) * 0.1, 1),
            "production_total": round(
                u32(register(96), register(97)) * 0.1, 1
            ),
        },
        "battery": {
            "voltage": round(register(183) * 0.01, 2),
            "soc": register(184),
            "current": round(s16(register(191)) * 0.01, 2),
            "power": s16(register(190)),
            "temperature": round((register(182) - 1000) * 0.1, 1),
        },
        "grid": {
            # Register mapping needs verification.
            "voltage_raw": register(150),
            "power": s16(register(169)),
        },
        "load": {
            "power": s16(register(178)),
            "frequency": round(register(192) * 0.01, 2),
        },
        "inverter": {
            "frequency": round(register(193) * 0.01, 2),
            # Temperature conversion needs verification.
            "dc_temperature_raw": register(90),
            "ac_temperature_raw": register(91),
        },
    }


def main():
    args = parse_args()
    try:
        metrics = read_metrics(args)
        print(json.dumps(metrics, separators=(",", ":"), ensure_ascii=False))
    except Exception as exc:
        print(f"Deye monitoring error: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
