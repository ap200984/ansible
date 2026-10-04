import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

HELPER = Path(__file__).resolve().parents[1] / 'files/migrate-network.py'


class NetworkMigrationTests(unittest.TestCase):
    def migrate(self, config, arguments):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'wg0.conf'
            path.write_text(config)
            script = HELPER.read_text().replace("Path('/etc/wireguard')", f'Path({directory!r})')
            command = [sys.executable, '-c', script, '--interface', 'wg0', *arguments]
            first = subprocess.run(command, text=True, capture_output=True, check=True)
            result = path.read_text()
            second = subprocess.run(command, text=True, capture_output=True, check=True)
            self.assertIn('CONFIG_CHANGED', first.stdout)
            self.assertIn('CONFIG_UNCHANGED', second.stdout)
            self.assertEqual(result, path.read_text())
            self.assertIn('PrivateKey = unchanged-secret', result)
            return result

    def test_client_preserves_key_nat_and_existing_lan_permissions(self):
        result = self.migrate(
            '[Interface]\nAddress = 10.250.6.7/32\nPrivateKey = unchanged-secret\n'
            'PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE\n'
            '\n[Peer]\nPublicKey = target-key\nAllowedIPs = 10.250.7.6/32, 10.9.0.0/24\n',
            ['--address', '10.250.1.6/32', '--peer-key', 'target-key',
             '--old-remote', '10.250.7.6', '--client', '--port', '56696'])
        self.assertIn('Address = 10.250.1.6/32', result)
        self.assertIn('10.9.0.0/24, 10.250.0.0/16, 10.255.0.0/16', result)
        self.assertNotIn('10.250.7.6', result)
        self.assertIn('MASQUERADE', result)

    def test_shared_hub_preserves_other_peer_ownership(self):
        result = self.migrate(
            '[Interface]\nAddress = 10.250.8.7/32, 10.250.1.8/21\nPrivateKey = unchanged-secret\n'
            '\n[Peer]\nPublicKey = target-key\nAllowedIPs = 10.250.7.8/32, 10.250.7.0/24, 10.255.0.7/32\n'
            '\n[Peer]\nPublicKey = other-key\nAllowedIPs = 10.250.1.112/32\n',
            ['--address', '10.250.1.8/24', '--peer-key', 'target-key',
             '--old-remote', '10.250.7.8', '--old-prefix', '10.250.7.0/24',
             '--remote-prefix', '10.250.1.0/28'])
        self.assertIn('AllowedIPs = 10.255.0.7/32, 10.250.1.0/28', result)
        self.assertIn('PublicKey = other-key\nAllowedIPs = 10.250.1.112/32', result)
        self.assertNotIn('10.250.7.', result)


if __name__ == '__main__':
    unittest.main()
