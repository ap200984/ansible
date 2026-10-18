import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('configure', Path(__file__).parents[1] / 'files/configure.py')
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)

class MigrationTests(unittest.TestCase):
    original = '[Interface]\nPrivateKey = original-key\nPostUp = ip route replace 10.250.1.24/32 dev %i\n\n[Peer]\nPublicKey = ' + helper.Misha_KEY + '\nAllowedIPs = 10.255.0.24/32\n\n[Peer]\nPublicKey = other-site\nAllowedIPs = 10.255.0.64/32\n'

    def test_native_retains_identity_and_uses_dedicated_transport(self):
        native = helper.prepare(self.original, 8)
        self.assertIn('PrivateKey = original-key', native)
        self.assertIn('Address = 10.250.6.8/24', native)
        self.assertIn('PublicKey = ' + helper.Misha_KEY, native)
        self.assertIn('Table = off', native)
        self.assertIn('AllowedIPs = 10.0.0.0/8, 224.0.0.5/32', native)
        self.assertNotIn('other-site', native)

    def test_cutover_preserves_other_sites_and_is_idempotent(self):
        plain = helper.remove_peer(self.original)
        self.assertNotIn(helper.Misha_KEY, plain)
        self.assertNotIn('10.250.1.24/32', plain)
        self.assertIn('PublicKey = other-site', plain)
        self.assertIn('AllowedIPs = 10.255.0.64/32', plain)
        self.assertIn('PrivateKey = original-key', plain)
        self.assertEqual(helper.remove_peer(plain), plain)

if __name__ == '__main__':
    unittest.main()
