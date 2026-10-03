"""Regression checks for export syntax seen on the managed routers."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'module_utils'))
from routeros_export import parse_export, split


class ExportTests(unittest.TestCase):
    def test_nested_wifi_properties(self):
        record = parse_export('/interface wifi set [ find default-name=wifi1 ] '
                              'channel.band=5ghz-ax .width=20mhz security.passphrase="test\\$value" .ft=yes')[0]
        self.assertEqual(record['selector'], {'default-name': 'wifi1'})
        self.assertEqual(record['values'], {'channel.band': '5ghz-ax', 'channel.width': '20mhz',
                         'security.passphrase': 'test$value', 'security.ft': 'yes'})

    def test_flags_and_unset(self):
        self.assertEqual(parse_export('/routing table add fib name=main')[0]['values'],
                         {'fib': 'yes', 'name': 'main'})
        record = parse_export('/system scheduler add !days name=job')[0]
        self.assertEqual(record['values']['days'], '')
        self.assertEqual(record['unset'], ['days'])

    def test_continued_script_and_escapes(self):
        record = parse_export('/system script add name=example source="line1\\r\\n\\\n'
                              '    line2\\? \\"quoted\\" \\$value"')[0]
        self.assertEqual(record['values']['source'], 'line1\r\nline2? "quoted" $value')
        self.assertEqual(split('comment="" name="two words"'), ['comment=', 'name=two words'])

    def test_named_and_numbered_defaults(self):
        self.assertEqual(parse_export('/routing bgp template set default disabled=no')[0]['selector'],
                         {'name': 'default'})
        self.assertEqual(parse_export('/system logging action set 3 remote=10.9.0.76')[0]['number'], 3)


if __name__ == '__main__':
    unittest.main()
