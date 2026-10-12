import importlib.util
from pathlib import Path
import unittest
spec = importlib.util.spec_from_file_location('source', Path(__file__).parents[1] / 'files/set-loopback-source.py')
source = importlib.util.module_from_spec(spec)
spec.loader.exec_module(source)

class SourcePolicyTests(unittest.TestCase):
    def test_preserves_dynamic_protocol_nexthop_group_and_metric(self):
        cmd = source.source_command({'dst':'10.255.0.112','nhid':72,'metric':20}, '10.255.0.6')
        self.assertEqual(cmd, ['ip','-4','route','replace','10.255.0.112/32','table','main','proto','ospf','nhid','72','metric','20','src','10.255.0.6'])
    def test_preserves_explicit_nexthop(self):
        cmd = source.source_command({'dst':'10.255.0.112','gateway':'10.250.2.5','dev':'wg1'}, '10.255.0.6')
        self.assertIn('10.250.2.5',cmd)
        self.assertIn('wg1',cmd)
    def test_unrelated_and_already_correct_routes_are_untouched(self):
        for route in [{'dst':'default'},{'dst':'10.9.0.0/24'},{'dst':'8.8.8.8'},{'dst':'10.255.0.112','prefsrc':'10.255.0.6'}]:
            self.assertIsNone(source.source_command(route,'10.255.0.6'))
    def test_refuses_to_lose_route_information(self):
        for route in [{'dst':'10.255.0.112'},{'dst':'10.255.0.112','type':'blackhole'},{'dst':'10.255.0.112','nhid':72,'metrics':{'mtu':1300}}]:
            with self.assertRaises(ValueError):source.source_command(route,'10.255.0.6')
