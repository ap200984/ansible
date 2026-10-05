import contextlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

HELPER = Path(__file__).resolve().parents[1] / 'files/configure-ospf.py'
NETWORKS = ['10.9.0.0/24', '10.9.1.0/24', '10.250.0.0/24',
            '10.250.1.0/24', '10.250.3.0/24', '10.255.0.0/24']


class OspfConfigurationTests(unittest.TestCase):
    def configure(self, config, ownership=None):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'wg0.conf'
            path.write_text(config)
            script = HELPER.read_text().replace("Path('/etc/wireguard')", f'Path({directory!r})')
            argv = ['configure-ospf', '--interface', 'wg0', '--address', '10.250.1.2/24',
                    '--loopback', '10.255.0.2/32', '--networks', json.dumps(NETWORKS),
                    '--peers', json.dumps(ownership or {})]
            with patch.object(sys, 'argv', argv), patch('subprocess.run') as run, \
                    patch('subprocess.check_output', return_value=b'configuration'), \
                    contextlib.redirect_stdout(io.StringIO()):
                exec(compile(script, str(HELPER), 'exec'), {'__name__': '__main__'})
                result = path.read_text()
                exec(compile(script, str(HELPER), 'exec'), {'__name__': '__main__'})
                self.assertEqual(result, path.read_text(), 'Reapplication must be idempotent')
                deletions = [call.args[0] for call in run.call_args_list if call.args[0][:3] == ['ip', 'route', 'del']]
                self.assertTrue(deletions)
                self.assertTrue(all(cmd[-4:] == ['scope', 'link', 'proto', 'boot'] for cmd in deletions))
            self.assertIn('PrivateKey = unchanged-secret', result)
            self.assertIn('Table = off', result)
            self.assertIn('PostUp = ip address replace 10.255.0.2/32 dev lo', result)
            return result

    def test_client_replaces_broad_ranges_and_preserves_unrelated_lans(self):
        result = self.configure('[Interface]\nAddress = 10.250.1.2/32\nPrivateKey = unchanged-secret\n'
                                'PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE\n'
                                '[Peer]\nPublicKey = client\nAllowedIPs = 10.250.0.0/16, 10.255.0.0/16, 10.10.0.0/24\n')
        self.assertNotIn('10.250.0.0/16', result)
        self.assertNotIn('10.255.0.0/16', result)
        for prefix in NETWORKS + ['10.10.0.0/24']:
            self.assertIn(prefix, result)
        self.assertIn('MASQUERADE', result)

    def test_shared_interface_uses_explicit_ownership(self):
        result = self.configure('[Interface]\nAddress = 10.250.1.1/21\nPrivateKey = unchanged-secret\n'
                                '[Peer]\nPublicKey = site\nAllowedIPs = 10.9.0.0/16\n'
                                '[Peer]\nPublicKey = hub\nAllowedIPs = 10.250.1.0/28\n',
                                {'site': NETWORKS[:2] + ['10.250.1.112/32'], 'hub': NETWORKS[2:]})
        self.assertNotIn('/21', result)
        self.assertNotIn('10.9.0.0/16', result)
        self.assertIn('PublicKey = site\nAllowedIPs = 10.9.0.0/24, 10.9.1.0/24, 10.250.1.112/32', result)


if __name__ == '__main__':
    unittest.main()
