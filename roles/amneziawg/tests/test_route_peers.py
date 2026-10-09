import importlib.util
from pathlib import Path
import unittest

MODULE = Path(__file__).resolve().parents[1] / 'files' / 'route-peers.py'
SPEC = importlib.util.spec_from_file_location('awg_routes', MODULE)
routes = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(routes)


class RouteOwnershipTests(unittest.TestCase):
    peers = {'10.250.2.1': 'key1', '10.250.2.8': 'key8'}

    def test_direct_neighbors_are_always_reachable(self):
        result = routes.desired_prefixes(self.peers, [])
        self.assertEqual(result['key1'], ['10.250.2.1/32', '10.255.0.1/32'])

    def test_routed_lan_belongs_to_next_hop(self):
        result = routes.desired_prefixes(self.peers, [
            {'dst': '10.9.0.0/24', 'gateway': '10.250.2.1'}])
        self.assertIn('10.9.0.0/24', result['key1'])
        self.assertNotIn('10.9.0.0/24', result['key8'])

    def test_failover_moves_loopback_ownership(self):
        result = routes.desired_prefixes(self.peers, [
            {'dst': '10.255.0.1/32', 'gateway': '10.250.2.8'}])
        self.assertNotIn('10.255.0.1/32', result['key1'])
        self.assertIn('10.255.0.1/32', result['key8'])

    def test_unicast_neighbor_routes_are_not_reassigned(self):
        result = routes.desired_prefixes(self.peers, [
            {'dst': '10.250.2.1/32', 'gateway': '10.250.2.8'}])
        self.assertIn('10.250.2.1/32', result['key1'])

    def test_external_and_default_routes_are_excluded(self):
        result = routes.desired_prefixes(self.peers, [
            {'dst': 'default', 'gateway': '10.250.2.1'},
            {'dst': '172.20.0.0/16', 'gateway': '10.250.2.8'}])
        self.assertEqual(sum(map(len, result.values())), 4)

    def test_single_nexthop_array_is_supported(self):
        result = routes.desired_prefixes(self.peers, [
            {'dst': '10.9.1.0/24', 'nexthops': [{'gateway': '10.250.2.8'}]}])
        self.assertIn('10.9.1.0/24', result['key8'])

    def test_ecmp_is_rejected_instead_of_arbitrary_peer_selection(self):
        with self.assertRaises(ValueError):
            routes.desired_prefixes(self.peers, [
                {'dst': '10.9.0.0/24', 'nexthops': [
                    {'gateway': '10.250.2.1'}, {'gateway': '10.250.2.8'}]}])

    def test_unknown_next_hop_does_not_gain_permissions(self):
        result = routes.desired_prefixes(self.peers, [
            {'dst': '10.9.0.0/24', 'gateway': '10.250.2.99'}])
        self.assertEqual(sum(map(len, result.values())), 4)

    def test_custom_mesh_suffix_does_not_change_router_loopback(self):
        result = routes.desired_prefixes({'10.250.2.130': 'key2'}, [],
                                         {'10.250.2.130': '10.255.0.2/32'})
        self.assertIn('10.255.0.2/32', result['key2'])
        self.assertNotIn('10.255.0.130/32', result['key2'])

    def test_chr_multicast_permission_survives_reconciliation(self):
        result = routes.desired_prefixes({'10.250.1.7': 'key7'}, [],
                                         fixed={'10.250.1.7': ['224.0.0.5/32']})
        self.assertIn('224.0.0.5/32', result['key7'])


if __name__ == '__main__':
    unittest.main()
