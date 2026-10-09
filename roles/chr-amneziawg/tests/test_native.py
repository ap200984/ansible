import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('native', ROOT / 'files/native-migrate.py')
native = importlib.util.module_from_spec(spec)
spec.loader.exec_module(native)


class NativeMigrationTests(unittest.TestCase):
    def test_preserves_identity_and_unrelated_peers(self):
        original = ('[Interface]\nPrivateKey = PRIVATE\nAddress = 10.250.1.8/24\n'
                    'PostUp = ip route replace 10.250.1.7/32 dev %i\n'
                    'PostUp = ip route replace 10.250.1.21/32 dev %i\n'
                    '[Peer]\nPublicKey = CHR\nAllowedIPs = 10.0.0.0/8\n'
                    '[Peer]\nPublicKey = SITE\nAllowedIPs = 10.11.0.0/16\n')
        plain, awg = native.prepare(original, 'CHR', 8)
        self.assertNotIn('PublicKey = CHR', plain)
        self.assertNotIn('10.250.1.7/32', plain)
        self.assertIn('PublicKey = SITE', plain)
        self.assertIn('10.250.1.21/32', plain)
        self.assertIn('PrivateKey = PRIVATE', awg)
        self.assertIn('Address = 10.250.1.8/24', awg)
        self.assertIn('224.0.0.5/32', awg)
        self.assertIn('Table = off', awg)
        self.assertNotIn('Endpoint =', awg)
        self.assertIn('PersistentKeepalive = 0', awg)

    def test_refuses_missing_peer(self):
        with self.assertRaises(ValueError):
            native.prepare('[Interface]\nPrivateKey = PRIVATE\n[Peer]\nPublicKey = SITE\n', 'CHR', 2)

    def test_verification_accepts_both_keepalive_formats(self):
        import subprocess
        check = '$2 != "off" && $2 != "0" {exit 1}'
        for value, expected in [('off', 0), ('0', 0), ('25', 1)]:
            result = subprocess.run(['awk', check], input=f'PUBLIC\t{value}\n', text=True)
            self.assertEqual(result.returncode, expected)

    def test_router_cutover_pins_return_transport_without_nat(self):
        from jinja2 import Environment
        template = ROOT.parents[1] / 'mikrotik/templates/chr-native-cutover.rsc.j2'
        rendered = Environment().from_string(template.read_text()).render(
            inventory_hostname='vds8', native_chr_allowed='10.250.1.0/24')
        self.assertIn('gateway=10.250.1.8%vds8_interface', rendered)
        self.assertIn('224.0.0.5/32', rendered)
        self.assertIn('type=ptp', rendered)
        self.assertNotIn('nat', rendered)


if __name__ == '__main__':
    unittest.main()
