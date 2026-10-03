"""Captures should only change when configuration changes."""
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from capture import extract_secrets, normalize_export, portable_key_path, records


class CaptureTests(unittest.TestCase):
    def test_key_path_is_portable_across_home_directories(self):
        for home in ('/home/user', '/Users/alexander'):
            with patch('capture.Path.home', return_value=Path(home)):
                self.assertEqual(portable_key_path(home + '/.ssh/priv/ansible'),
                                 '~/.ssh/priv/ansible')
                self.assertEqual(portable_key_path('/etc/ssh/custom_key'),
                                 '/etc/ssh/custom_key')

    def test_existing_reference_survives_removed_record(self):
        previous = records('/interface wireguard add name=removed\n'
                           '/ppp secret add name=trepko_home password=hidden')
        previous[1]['values']['password'] = '{{ routeros_secrets.record_393_password }}'
        desired = records('/ppp secret add name=trepko_home password=actual')
        public = records('/ppp secret add name=trepko_home')
        self.assertEqual(extract_secrets(desired, public, previous),
                         {'record_393_password': 'actual'})
        self.assertEqual(desired[0]['values']['password'], previous[1]['values']['password'])

    def test_new_references_do_not_depend_on_order_or_password(self):
        def capture(prefix, password):
            desired = records(prefix + '/ppp secret add name=home password=' + password)
            public = records(prefix + '/ppp secret add name=home')
            return next(iter(extract_secrets(desired, public)))
        self.assertEqual(capture('', 'first'),
                         capture('/interface bridge add name=LAN\n', 'second'))

    def test_timestamp_ignored_version_preserved(self):
        self.assertEqual(normalize_export('# 2026-10-03 20:04:23 by RouterOS 7.24.5\n'),
                         '# by RouterOS 7.24.5\n')
        self.assertEqual(normalize_export('# by RouterOS 7.24.5\n'),
                         '# by RouterOS 7.24.5\n')
