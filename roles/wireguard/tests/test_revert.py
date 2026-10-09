import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('revert_awg', Path(__file__).parents[1] / 'files/revert-awg.py')
revert = importlib.util.module_from_spec(spec)
spec.loader.exec_module(revert)


class PlainReplacementTests(unittest.TestCase):
    def test_config_keeps_ospf_and_disables_automatic_routes_and_keepalive(self):
        conf = revert.config('10.250.2.2', 56702, 'test-private', 'test-public',
                             '217.144.189.206:56712', '10.250.2.5')
        for value in ['Address = 10.250.2.2/24', 'MTU = 1340', 'Table = off',
                      'AllowedIPs = 10.0.0.0/8, 224.0.0.5/32', 'PersistentKeepalive = 0']:
            self.assertIn(value, conf)
        self.assertNotIn('Jc', conf)

    def test_replaces_only_exact_interface(self):
        text = 'interface wg1\n old\n!\ninterface wg-vds2\n keep\n!\nrouter ospf\n!\n'
        result = revert.replace_interface(text, 'wg1', revert.ospf_interface('wg1', '10.250.2.2', 200))
        self.assertIn('interface wg-vds2\n keep\n!', result)
        self.assertNotIn(' old', result)
        self.assertIn('ip ospf network point-to-point', result)

    def test_can_retire_native_chr_interface(self):
        result = revert.replace_interface('interface wg2\n old\n!\nrouter ospf\n!\n', 'wg2', '')
        self.assertEqual(result, 'router ospf\n!\n')
