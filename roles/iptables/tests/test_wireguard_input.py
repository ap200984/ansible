"""Exercise firewall normalization without touching the host firewall."""
import json
from pathlib import Path
import shlex
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from jinja2 import Environment


class WireGuardInputTest(unittest.TestCase):
    def normalize(self, rules, sources):
        environment = Environment()
        environment.filters['to_json'] = json.dumps
        template = Path(__file__).parents[1] / 'templates/trusted-rule-cleanup.py.j2'
        code = environment.from_string(template.read_text()).render(
            trusted_networks=['10.255.0.0/24'], trusted_hosts=['192.0.2.1/32'],
            iptables_input_ssh_port=19022, iptables_input_wireguard_port=56699,
            iptables_input_wireguard_sources=sources,
        )

        def exported():
            return '\n'.join(shlex.join(['-A', 'INPUT', *rule]) for rule in rules)

        def run(arguments, **kwargs):
            if arguments[:3] == ['iptables', '-D', 'INPUT']:
                rules.remove(arguments[3:])
            elif arguments[:4] == ['iptables', '-I', 'INPUT', '1']:
                rules.insert(0, arguments[4:])
            return SimpleNamespace(returncode=0, stdout='')

        with patch('subprocess.check_output', side_effect=lambda *a, **k: exported()), patch(
            'subprocess.run', side_effect=run,
        ):
            exec(compile(code, str(template), 'exec'), {})

    def test_scoped_rules_survive_repeated_cleanup_without_duplicates(self):
        rules = []
        sources = ['94.141.127.11/32', '95.27.205.192/32']
        self.normalize(rules, sources)
        first = [rule[:] for rule in rules]
        self.normalize(rules, sources)
        self.assertEqual(rules, first)
        vpn_rules = [rule for rule in rules if 'ansible-wireguard-peer' in rule]
        self.assertEqual(len(vpn_rules), 2)
        for source in sources:
            self.assertIn([
                '-s', source, '-p', 'udp', '-m', 'udp', '--dport', '56699',
                '-m', 'comment', '--comment', 'ansible-wireguard-peer', '-j', 'ACCEPT',
            ], vpn_rules)

    def test_no_listener_exception_without_configured_sources(self):
        rules = []
        self.normalize(rules, [])
        self.assertFalse(any('udp' in rule for rule in rules))

    def test_removing_a_source_revokes_its_managed_exception(self):
        rules = []
        self.normalize(rules, ['94.141.127.11/32', '95.27.205.192/32'])
        self.normalize(rules, ['95.27.205.192/32'])
        self.assertFalse(any('94.141.127.11/32' in rule for rule in rules))
        self.assertEqual(sum('ansible-wireguard-peer' in rule for rule in rules), 1)

    def test_public_listener_replaces_scoped_rules_and_survives_cleanup(self):
        rules = []
        self.normalize(rules, ['94.141.127.11/32', '95.27.205.192/32'])
        self.normalize(rules, ['0.0.0.0/0'])
        expected = [
            '-p', 'udp', '-m', 'udp', '--dport', '56699',
            '-m', 'comment', '--comment', 'ansible-wireguard-peer', '-j', 'ACCEPT',
        ]
        self.assertEqual([r for r in rules if 'ansible-wireguard-peer' in r], [expected])
        first = [r[:] for r in rules]
        self.normalize(rules, ['0.0.0.0/0'])
        self.assertEqual(rules, first)


if __name__ == '__main__':
    unittest.main()
