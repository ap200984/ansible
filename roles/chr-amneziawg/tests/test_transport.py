import base64
from pathlib import Path
import unittest

import yaml
from jinja2 import Environment
from jinja2.nativetypes import NativeEnvironment


ROOT = Path(__file__).resolve().parents[3]
CONFIG = yaml.safe_load((ROOT / 'mikrotik/vars/chr-amneziawg.yml').read_text())


class TransportTests(unittest.TestCase):
    def test_public_identities_are_valid(self):
        self.assertEqual(set(CONFIG['chr_awg_chr_keys']), {'vds1', 'vds2', 'vds5', 'vds6', 'vds8'})
        for key in CONFIG['chr_awg_chr_keys'].values():
            self.assertEqual(len(base64.b64decode(key, validate=True)), 32)

    def test_artifacts_are_checksum_pinned(self):
        for kind in ('binary', 'image'):
            self.assertRegex(CONFIG[f'chr_awg_{kind}_sha256'], r'^[a-f0-9]{64}$')
        self.assertNotEqual(CONFIG['chr_awg_port'], 56702)

    def test_firewall_does_not_nat_or_block_other_peers(self):
        template = (ROOT / 'roles/chr-amneziawg/templates/firewall.sh.j2').read_text()
        values = dict(CONFIG, chr_awg_wg_port={'stdout': '56685'})
        rendered = Environment().from_string(template).render(**values)
        self.assertNotIn('POSTROUTING', rendered)
        self.assertNotIn('masquerade', rendered)
        drops = [line for line in rendered.splitlines() if '-j DROP' in line]
        self.assertEqual(len(drops), 4)
        self.assertTrue(all('62.60.216.73/32' in line and '56685' in line for line in drops))

    def test_cutover_preserves_addresses_keys_and_ospf_costs(self):
        template = (ROOT / 'mikrotik/templates/chr-awg-cutover.rsc.j2').read_text()
        self.assertIn('persistent-keepalive=0', template)
        for forbidden in ('private-key', 'public-key', '/ip address', '/routing ospf', '/ip firewall nat'):
            self.assertNotIn(forbidden, template)

    def test_router_command_arguments_render_with_native_integer_suffix(self):
        env = NativeEnvironment()
        values = dict(CONFIG, chr_awg_peer='vds1', chr_awg_suffix=1,
                      chr_awg_ssh=['ssh'], chr_awg_veth='veth-awg-vds1',
                      chr_awg_env='awg-vds1', chr_awg_gateway='172.31.70.5',
                      chr_awg_container_ip='172.31.70.6',
                      amneziawg_endpoints={'vds1': '45.141.102.72'},
                      hostvars={'vds1': {'chr_awg_linux_key': {'stdout': 'test-public-key'}}})
        def lookup(kind, name):
            self.assertEqual(kind, 'template')
            return env.from_string((ROOT / 'mikrotik' / name).read_text()).render(**values)
        values['lookup'] = lookup
        tasks = yaml.safe_load((ROOT / 'mikrotik/chr-amneziawg-peer.yml').read_text())
        commands = []
        def walk(entries):
            for task in entries:
                for key in ('block', 'rescue'):
                    walk(task.get(key, []))
                args = task.get('ansible.builtin.command', {})
                if isinstance(args, dict) and isinstance(args.get('argv'), str):
                    commands.append(env.from_string(args['argv']).render(**values))
        walk(tasks)
        self.assertGreater(len(commands), 5)
        for argv in commands:
            self.assertIsInstance(argv, list)
            self.assertTrue(all(isinstance(arg, str) for arg in argv))
            if argv[0] == 'ssh':
                self.assertNotIn('\n', argv[-1])
                self.assertNotIn('\\"', argv[-1])

    def test_wireguard_reapply_preserves_proxy_bootstrap_and_other_endpoints(self):
        env = Environment()
        env.filters['bool'] = bool
        template = (ROOT / 'roles/wireguard/templates/wg.conf.j2').read_text()
        rendered = env.from_string(template).render(
            wireguard_addresses=['10.250.1.1/24'], wireguard_private_key='test-key',
            wireguard_listen_port=56685, wireguard_mtu=1420,
            wireguard_peers=[
                {'name': 'CHR', 'public_key': CONFIG['chr_awg_chr_keys']['vds1'],
                 'endpoint': '62.60.216.73:56697', 'allowed_ips': ['10.255.0.7/32'], 'persistent_keepalive': 25},
                {'name': 'site', 'public_key': 'test-public-key',
                 'endpoint': '86.110.170.70:37973', 'allowed_ips': ['10.255.0.112/32'], 'persistent_keepalive': 25}],
            chr_amneziawg_transport_enabled=True)
        self.assertNotIn('Endpoint = 62.60.216.73', rendered)
        self.assertIn('Endpoint = 86.110.170.70:37973', rendered)
        self.assertIn('CHR endpoint learned', rendered)
        self.assertEqual(rendered.count('PersistentKeepalive = 25'), 1)


if __name__ == '__main__':
    unittest.main()
