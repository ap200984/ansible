import importlib.util
import json
from pathlib import Path
import unittest
from unittest.mock import patch

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

    def test_leaf_transport_sources_follow_the_advertised_loopback(self):
        aliases = {'10.255.0.2/32': ['10.250.1.2/32', '10.250.2.2/32']}
        result = routes.desired_prefixes(self.peers, [
            {'dst': '10.255.0.2/32', 'gateway': '10.250.2.1'}], source_aliases=aliases)
        self.assertIn('10.250.1.2/32', result['key1'])
        self.assertIn('10.250.2.2/32', result['key1'])
        self.assertNotIn('10.250.2.2/32', result['key8'])

    def test_source_aliases_move_with_loopback_failover(self):
        aliases = {'10.255.0.6/32': ['10.250.1.6/32', '10.250.2.6/32']}
        result = routes.desired_prefixes(self.peers, [
            {'dst': '10.255.0.6/32', 'gateway': '10.250.2.8'}], source_aliases=aliases)
        self.assertIn('10.250.1.6/32', result['key8'])
        self.assertIn('10.250.2.6/32', result['key8'])
        self.assertNotIn('10.250.2.6/32', result['key1'])

    def test_explicit_destination_ownership_wins_over_source_alias_inference(self):
        result = routes.desired_prefixes(self.peers, [
            {'dst': '10.255.0.2/32', 'gateway': '10.250.2.1'},
            {'dst': '10.250.1.2/32', 'gateway': '10.250.2.8'}],
            source_aliases={'10.255.0.2/32': ['10.250.1.2/32']})
        self.assertIn('10.250.1.2/32', result['key8'])
        self.assertNotIn('10.250.1.2/32', result['key1'])

    def test_direct_transport_ownership_is_never_stolen_by_an_alias(self):
        result = routes.desired_prefixes(self.peers, [
            {'dst': '10.255.0.1/32', 'gateway': '10.250.2.8'}],
            source_aliases={'10.255.0.1/32': ['10.250.2.1/32', '10.250.1.1/32']})
        self.assertIn('10.250.2.1/32', result['key1'])
        self.assertNotIn('10.250.2.1/32', result['key8'])
        self.assertIn('10.250.1.1/32', result['key8'])

    def test_unreachable_or_local_loopbacks_do_not_grant_transport_aliases(self):
        result = routes.desired_prefixes(self.peers, [],
            source_aliases={'10.255.0.2/32': ['10.250.1.2/32', '10.250.2.2/32']})
        self.assertEqual(sum(map(len, result.values())), 4)

    def test_fixed_ownership_takes_precedence_over_inferred_source_alias(self):
        result = routes.desired_prefixes(self.peers, [
            {'dst': '10.255.0.2/32', 'gateway': '10.250.2.1'}],
            fixed={'10.250.2.8': ['10.250.1.2/32']},
            source_aliases={'10.255.0.2/32': ['10.250.1.2/32']})
        self.assertIn('10.250.1.2/32', result['key8'])
        self.assertNotIn('10.250.1.2/32', result['key1'])

    def test_multiple_anchors_for_one_source_alias_are_rejected(self):
        with self.assertRaises(ValueError):
            routes.desired_prefixes(self.peers, [], source_aliases={
                '10.255.0.1/32': ['10.250.1.2/32'],
                '10.255.0.8/32': ['10.250.1.2/32']})

    def test_source_aliases_cannot_introduce_broad_or_public_permissions(self):
        for alias in ['10.250.2.0/24', '0.0.0.0/0', '192.0.2.1/32', '::1/128']:
            with self.subTest(alias=alias), self.assertRaises(ValueError):
                routes.desired_prefixes(self.peers, [],
                    source_aliases={'10.255.0.1/32': [alias]})

    def test_native_static_permissions_survive_without_an_ospf_route(self):
        result = routes.desired_prefixes(self.peers, [],
            fallback={'10.250.2.1': ['10.10.0.0/16', '10.250.0.64/32']})
        self.assertIn('10.10.0.0/16', result['key1'])
        self.assertIn('10.250.0.64/32', result['key1'])

    def test_ospf_next_hop_overrides_legacy_static_permission(self):
        result = routes.desired_prefixes(self.peers, [
            {'dst': '10.250.3.112/32', 'gateway': '10.250.2.8'}],
            fallback={'10.250.2.1': ['10.250.3.112/32']})
        self.assertIn('10.250.3.112/32', result['key8'])
        self.assertNotIn('10.250.3.112/32', result['key1'])

    def test_source_alias_overrides_legacy_static_permission(self):
        result = routes.desired_prefixes(self.peers, [
            {'dst': '10.255.0.64/32', 'gateway': '10.250.2.8'}],
            source_aliases={'10.255.0.64/32': ['10.250.0.64/32']},
            fallback={'10.250.2.1': ['10.250.0.64/32']})
        self.assertIn('10.250.0.64/32', result['key8'])
        self.assertNotIn('10.250.0.64/32', result['key1'])

    def test_direct_neighbor_and_multicast_override_fallback(self):
        result = routes.desired_prefixes(self.peers, [],
            fallback={'10.250.2.8': ['10.250.2.1/32', '224.0.0.5/32']},
            fixed={'10.250.2.1': ['224.0.0.5/32']})
        self.assertIn('10.250.2.1/32', result['key1'])
        self.assertIn('224.0.0.5/32', result['key1'])
        self.assertNotIn('10.250.2.1/32', result['key8'])


class NativeReconcileTests(unittest.TestCase):
    config = {'interface': 'wg0', 'command': 'wg', 'peers': {
        '10.250.1.64': 'key64', '10.250.1.21': 'key21'},
        'fallback': {'10.250.1.64': ['10.10.0.0/16']}}

    @patch.object(routes.subprocess, 'run')
    @patch.object(routes.subprocess, 'check_output')
    def test_native_reconcile_moves_learned_destination_without_kernel_routes(self, read, write):
        read.side_effect = [json.dumps([
            {'dst': '10.250.3.112/32', 'gateway': '10.250.1.21'}]),
            'key64\t10.250.1.64/32 10.255.0.64/32 10.10.0.0/16\n'
            'key21\t10.250.1.21/32 10.255.0.21/32\n']
        routes.reconcile(self.config)
        args = write.call_args.args[0]
        self.assertEqual(args[:3], ['wg', 'set', 'wg0'])
        self.assertIn('10.250.3.112/32', args[10].split(','))
        self.assertEqual(write.call_count, 1)

    @patch.object(routes.subprocess, 'run')
    @patch.object(routes.subprocess, 'check_output')
    def test_unexpected_live_peer_cannot_be_silently_discarded(self, read, write):
        read.side_effect = ['[]', 'key64\t10.250.1.64/32\n'
                            'key21\t10.250.1.21/32\nunknown\t10.0.0.0/8\n']
        with self.assertRaises(ValueError):
            routes.reconcile(self.config)
        write.assert_not_called()


if __name__ == '__main__':
    unittest.main()
