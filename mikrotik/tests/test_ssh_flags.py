"""RouterOS command regression coverage for passive and discard-route flags."""
import ast
from pathlib import Path
import unittest

module = ast.parse((Path(__file__).resolve().parents[1] / 'library/routeros_ssh.py').read_text())
namespace = {'re': __import__('re')}
functions = [node for node in module.body if isinstance(node, ast.FunctionDef) and node.name != 'main']
exec(compile(ast.Module(body=functions, type_ignores=[]), 'routeros_ssh', 'exec'), namespace)


class FlagTests(unittest.TestCase):
    def test_passive_advertisement_uses_cli_flag(self):
        command = namespace['script']({'path': '/routing ospf interface-template',
            'selector': {'comment': 'loopback'}, 'create': True, 'flags': ['passive'],
            'values': {'comment': 'loopback', 'interfaces': 'loopback', 'passive': 'yes'}}, False)
        self.assertIn('interfaces="loopback" passive;', command)
        self.assertNotIn('passive=', command)

    def test_blackhole_summary_uses_cli_flag(self):
        self.assertEqual(namespace['arguments']({'flags': ['blackhole'],
            'values': {'dst-address': '10.9.0.0/16', 'blackhole': 'yes'}}),
            'dst-address="10.9.0.0/16" blackhole')

    def test_active_ppp_is_not_passive(self):
        command = namespace['arguments']({'values': {'interfaces': 'sstp-vds7', 'type': 'ptp'}})
        self.assertNotIn('passive', command)
