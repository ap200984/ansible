"""Exercise the real helper with isolated state, time and ipset calls."""
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from jinja2 import Template

TEMPLATE = Path(__file__).parents[1] / 'templates/ssh-subnet-aggregate.py.j2'


class SubnetPolicyTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.state = Path(self.tmp.name) / 'state.json'
        self.code = Template(TEMPLATE.read_text()).render(
            ssh_bruteforce_ipset='TestBlacklist', ssh_bruteforce_findtime=600,
            ssh_bruteforce_subnet_maxretry=3, ssh_bruteforce_subnet_prefix=24,
            ssh_bruteforce_bantime=1209600,
        ).replace('/var/lib/fail2ban/ssh-subnet-attempts.json', str(self.state)).replace(
            '/run/lock/ssh-subnet-aggregate.lock', self.tmp.name + '/lock')
        self.calls = []

    def invoke(self, command, address, now=1000):
        with patch('sys.argv', ['helper', command, address]), patch('time.time', return_value=now), patch(
            'subprocess.run', side_effect=lambda args, **kwargs: self.calls.append(args)
        ):
            try:
                exec(compile(self.code, 'helper', 'exec'), {})
            except SystemExit as exc:
                return exc.code
        return 0

    def test_repeated_ip_triggers_only_third_failure(self):
        for expected in [0, 0, 1]:
            self.assertEqual(self.invoke('check', '198.51.100.1'), expected)
        self.assertEqual(self.calls, [])
        self.invoke('ban', '198.51.100.1')
        self.assertEqual(self.calls, [['ipset', 'add', 'TestBlacklist', '198.51.100.0/24',
                                     'timeout', '1209600', '-exist']])

    def test_mixed_addresses_share_counter_but_other_prefix_does_not(self):
        self.assertEqual(self.invoke('check', '198.51.100.1'), 0)
        self.assertEqual(self.invoke('check', '198.51.101.1'), 0)
        self.assertEqual(self.invoke('check', '198.51.100.2'), 0)
        self.assertEqual(self.invoke('check', '198.51.100.1'), 1)

    def test_expired_failures_do_not_count(self):
        self.invoke('check', '198.51.100.1', 1000)
        self.invoke('check', '198.51.100.1', 1001)
        self.assertEqual(self.invoke('check', '198.51.100.1', 1602), 0)
        self.assertEqual(json.loads(self.state.read_text()), {'198.51.100.0/24': [1602]})

    def test_forget_removes_counter_and_prefix(self):
        self.invoke('add', '198.51.100.1')
        self.invoke('forget', '198.51.100.1')
        self.assertEqual(json.loads(self.state.read_text()), {})
        self.assertEqual(self.calls[-1], ['ipset', 'del', 'TestBlacklist', '198.51.100.0/24', '-exist'])


if __name__ == '__main__':
    unittest.main()
