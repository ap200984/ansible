import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('normalize', Path(__file__).parents[1] / 'files/normalize-linux.py')
normalize = importlib.util.module_from_spec(spec)
spec.loader.exec_module(normalize)


class ConsolidationTests(unittest.TestCase):
    def test_ordinary_mesh_uses_explicit_loopback_not_transport_suffix(self):
        interface = {'name': 'wg0', 'command': 'wg', 'addresses': ['10.250.1.2/24','10.250.2.130/25'],
                     'port': 56698, 'peers': [{'address': '10.250.2.133', 'source': '10.250.2.130',
                     'public': 'key5', 'loopback': '10.255.0.5/32', 'endpoint': '217.144.189.206:56695'}]}
        config = normalize.configuration(interface, 'test-private')
        self.assertIn('PersistentKeepalive = 0', config)
        self.assertNotIn('Jc', config)
        self.assertEqual(normalize.routing(interface)['loopbacks']['10.250.2.133'], '10.255.0.5/32')

    def test_chr_public_identity_and_multicast_are_preserved(self):
        interface = {'name': 'wg1', 'command': 'awg', 'addresses': ['10.250.2.1/25','10.250.1.1/24'],
                     'port': 56707, 'peers': [{'address': '10.250.1.7','source': '10.250.1.1',
                     'public': 'chr-key', 'loopback': '10.255.0.7/32', 'fixed': ['224.0.0.5/32']}]}
        config = normalize.configuration(interface, 'test-private')
        self.assertIn('PublicKey = chr-key', config)
        self.assertIn('ListenPort = 56707', config)
        self.assertNotIn('Endpoint =', config)
        self.assertEqual(normalize.routing(interface)['fixed']['10.250.1.7'], ['224.0.0.5/32'])
