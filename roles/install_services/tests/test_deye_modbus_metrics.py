"""Offline register decoding and wire-protocol checks; no inverter is required."""

import contextlib
import importlib.util
import io
import json
from pathlib import Path
import socket
import struct
import tempfile
import unittest
from unittest import mock


SCRIPT = Path(__file__).parents[1] / "files/zabbix_proxy/deye_modbus_metrics.py"
SPEC = importlib.util.spec_from_file_location("deye_modbus_metrics", SCRIPT)
deye = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(deye)


def register_fixture():
    registers = {address: 0 for start, count in deye.READ_BLOCKS
                 for address in range(start, start + count)}
    registers.update({
        26: 8000, 59: 2, 70: 123, 72: 65535, 73: 1,
        78: 1, 79: 5000, 80: 2, 90: 749, 91: 1223,
        96: 100, 97: 3, 108: 87, 109: 3345, 110: 65,
        111: 3310, 112: 72, 150: 2301, 160: 1234,
        169: 65535, 172: 32768, 175: 32767, 178: 1234,
        182: 1234, 183: 5234, 184: 89, 186: 1000, 187: 2000,
        190: 65036, 191: 65513, 193: 5001, 194: 1,
    })
    return registers


class FragmentedSocket:
    """Socket substitute that delivers every response in two-byte fragments."""

    def __init__(self, response):
        self.response = response
        self.requests = []
        self.closed = False
        self.timeout = None

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        self.closed = True

    def settimeout(self, timeout):
        self.timeout = timeout

    def sendall(self, request):
        self.requests.append(request)

    def recv(self, size):
        fragment = self.response[:min(size, 2)]
        self.response = self.response[len(fragment):]
        return fragment


def response_frame(pdu, tid=72, protocol=0, unit=1, length=None):
    return struct.pack(">HHHB", tid, protocol,
                       len(pdu) + 1 if length is None else length, unit) + pdu


class DecodeTests(unittest.TestCase):
    def test_engineering_units_signed_power_temperatures_and_counters(self):
        metrics, units = deye.decode(register_fixture())
        expected = {
            "RatedPower": 8000, "InverterRunState": 2,
            "DailyChargingEnergy": 12.3, "TotalChargeEnergy": 13107.1,
            "CumulativeEnergyPurchased": 13107.3, "GridFrequency": 50,
            "DC Temperature": -25.1, "AC Temperature": 22.3,
            "PVCumulativePowerGenerationActive": 19670.8,
            "PVDailyPowerGenerationActive": 8.7, "DCVoltagePV1": 334.5,
            "DCCurrentPV1": 6.5, "DCVoltagePV2": 331, "DCCurrentPV2": 7.2,
            "GridVoltageL1L2": 230.1, "GridCurrentL1L2": 12.34,
            "TotalGridPower": -1, "ExternalCTPowerL1L2": -32768,
            "InverterOutputPowerL1L2": 32767, "TotalConsumptionPower": 1234,
            "Temperature- Battery": 23.4, "BatteryVoltage": 52.34, "SOC": 89,
            "TotalDCInputPower": 3000, "BatteryPower": -500,
            "BatteryCurrent": -.23, "ACOutputFrequencyR": 50.01,
        }
        for key, value in expected.items():
            with self.subTest(metric=key):
                self.assertEqual(metrics[key], value)
        self.assertEqual(units["BatteryCurrent"], "A")
        self.assertEqual(units["TotalChargeEnergy"], "kWh")
        self.assertEqual(units["DC Temperature"], "°C")
        self.assertNotIn("InverterRunState", units)

    def test_attachment_aliases_match_sources(self):
        metrics, units = deye.decode(register_fixture())
        for alias, source in (
            ("DailyActiveProduction", "PVDailyPowerGenerationActive"),
            ("TotalActiveProduction", "PVCumulativePowerGenerationActive"),
            ("UPSLoadPower", "TotalConsumptionPower"),
        ):
            self.assertEqual(metrics[alias], metrics[source])
            self.assertEqual(units[alias], units[source])

    def test_missing_second_counter_word_fails_instead_of_emitting_partial_metrics(self):
        registers = register_fixture()
        del registers[80]
        with self.assertRaisesRegex(deye.ModbusError, "Missing register 80"):
            deye.decode(registers)

    def test_bad_register_values_are_rejected(self):
        for value in (-1, 65536, True, "123"):
            with self.subTest(value=value):
                registers = register_fixture()
                registers[26] = value
                with self.assertRaisesRegex(deye.ModbusError, "register 26"):
                    deye.decode(registers)

    def test_offline_dump_outputs_single_json_payload_without_network(self):
        with tempfile.TemporaryDirectory() as directory:
            dump = Path(directory) / "mbpoll.txt"
            dump.write_text("mbpoll status line\n" + "\n".join(
                f"[{address}]: {value}" for address, value in register_fixture().items()))
            stdout = io.StringIO()
            with mock.patch.object(deye.socket, "create_connection") as connect:
                with contextlib.redirect_stdout(stdout):
                    status = deye.main(["--from-dump", str(dump), "--raw"])
            connect.assert_not_called()
        self.assertEqual(status, 0)
        payload = json.loads(stdout.getvalue())
        self.assertEqual(len(stdout.getvalue().splitlines()), 1)
        self.assertEqual(payload["source"], "offline-mbpoll-dump")
        self.assertEqual(payload["unit_id"], 1)
        self.assertEqual(payload["metrics"]["BatteryPower"], -500)
        self.assertEqual(payload["registers"]["190"], 65036)
        self.assertTrue(payload["timestamp"].endswith("+00:00"))

    def test_dump_without_registers_or_unsigned_values_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            dump = Path(directory) / "mbpoll.txt"
            for content in ("no registers", "[1]: -1", "[1]: 65536", "[65536]: 0"):
                with self.subTest(content=content):
                    dump.write_text(content)
                    with self.assertRaises(ValueError):
                        deye.from_dump(dump)


class ProtocolTests(unittest.TestCase):
    def read(self, frame):
        connection = FragmentedSocket(frame)
        with mock.patch.object(deye.socket, "create_connection", return_value=connection) as connect:
            result = deye.read_block("inverter.lan", 502, 1, 70, 2, 3)
        connect.assert_called_once_with(("inverter.lan", 502), timeout=3)
        return result, connection

    def test_fragmented_response_and_exact_read_only_request(self):
        result, connection = self.read(response_frame(b"\x03\x04\x12\x34\xff\xff"))
        self.assertEqual(result, {70: 0x1234, 71: 65535})
        self.assertEqual(connection.requests, [struct.pack(">HHHBBHH", 72, 0, 6, 1, 3, 70, 2)])
        self.assertEqual(connection.timeout, 3)
        self.assertTrue(connection.closed)

    def test_mismatched_transaction_protocol_or_unit_is_rejected(self):
        for change in ({"tid": 73}, {"protocol": 1}, {"unit": 2}):
            with self.subTest(change=change):
                with self.assertRaisesRegex(deye.ModbusError, "response header"):
                    self.read(response_frame(b"\x03\x04\x00\x00\x00\x00", **change))

    def test_invalid_mbap_lengths_are_rejected(self):
        for length in (0, 1, 2, 255, 65535):
            with self.subTest(length=length):
                with self.assertRaisesRegex(deye.ModbusError, "TCP length"):
                    self.read(response_frame(b"", length=length))

    def test_exception_response_reports_code_and_register(self):
        with self.assertRaisesRegex(deye.ModbusError, "exception code 2 at register 70"):
            self.read(response_frame(b"\x83\x02"))
        with self.assertRaisesRegex(deye.ModbusError, "exception response length"):
            self.read(response_frame(b"\x83\x02\x00"))

    def test_wrong_function_count_or_trailing_payload_is_rejected(self):
        for pdu in (b"\x04\x04\x00\x00\x00\x00",
                    b"\x03\x02\x00\x00", b"\x03\x04\x00\x00\x00\x00\x00"):
            with self.subTest(pdu=pdu):
                with self.assertRaisesRegex(deye.ModbusError, "Invalid response for block"):
                    self.read(response_frame(pdu))

    def test_truncated_header_and_payload_fail_cleanly(self):
        for frame in (b"\x00", response_frame(b"\x03\x04\x00", length=7)):
            with self.subTest(frame=frame):
                with self.assertRaisesRegex(deye.ModbusError, "Connection closed"):
                    self.read(frame)

    def test_invalid_register_ranges_are_rejected_before_connecting(self):
        with mock.patch.object(deye.socket, "create_connection") as connect:
            for start, count in ((0, 0), (0, 126), (-1, 1), (65535, 2), (65536, 1)):
                with self.subTest(start=start, count=count):
                    with self.assertRaises(ValueError):
                        deye.read_block("inverter.lan", 502, 1, start, count, 3)
            connect.assert_not_called()


class CommandLineTests(unittest.TestCase):
    def test_positional_and_named_arguments_have_same_defaults(self):
        for argv in (["inverter.lan"], ["--host", "inverter.lan"]):
            args = deye.parse_args(argv)
            self.assertEqual((args.host, args.port, args.unit), ("inverter.lan", 502, 1))
        args = deye.parse_args(["10.10.0.196", "1502", "7"])
        self.assertEqual((args.host, args.port, args.unit), ("10.10.0.196", 1502, 7))

    def test_bad_arguments_exit_before_network_access(self):
        cases = ([], [""], ["bad host"], ["host", "0"], ["host", "65536"],
                 ["host", "502", "256"], ["host", "502", "-1"],
                 ["host", "--timeout", "0"], ["host", "--timeout", "-1"],
                 ["host", "--timeout", "nan"], ["host", "--timeout", "inf"],
                 ["host", "--host", "other"], ["host", "502", "--port", "502"])
        with mock.patch.object(deye.socket, "create_connection") as connect:
            for argv in cases:
                with self.subTest(argv=argv), contextlib.redirect_stderr(io.StringIO()):
                    with self.assertRaises(SystemExit) as error:
                        deye.main(argv)
                    self.assertEqual(error.exception.code, 2)
            connect.assert_not_called()

    def test_live_mode_reads_only_three_documented_blocks(self):
        registers = register_fixture()
        stdout = io.StringIO()
        with mock.patch.object(deye, "read_block", side_effect=lambda _h, _p, _u, start, count, _t:
                               {a: registers[a] for a in range(start, start + count)}) as read:
            with contextlib.redirect_stdout(stdout):
                self.assertEqual(deye.main(["::1", "1502", "7", "--timeout", "2"]), 0)
        self.assertEqual(read.call_args_list, [mock.call("::1", 1502, 7, start, count, 2)
                                              for start, count in deye.READ_BLOCKS])
        payload = json.loads(stdout.getvalue())
        self.assertEqual(payload["source"], "modbus-tcp://[::1]:1502")
        self.assertEqual(payload["unit_id"], 7)
        self.assertNotIn("registers", payload)

    def test_network_failure_writes_stderr_and_no_partial_json(self):
        for error in (socket.timeout("timed out"), OSError("connection refused"),
                      deye.ModbusError("bad response")):
            with self.subTest(error=error):
                stdout, stderr = io.StringIO(), io.StringIO()
                with mock.patch.object(deye, "read_block", side_effect=error):
                    with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                        self.assertEqual(deye.main(["host"]), 1)
                self.assertEqual(stdout.getvalue(), "")
                self.assertIn("Deye Modbus read failed:", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
