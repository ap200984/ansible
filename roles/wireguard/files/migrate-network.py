#!/usr/bin/env python3
"""Renumber an existing WireGuard link without replacing its keys or other peers."""
import argparse
import ipaddress
import re
import shutil
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument('--interface', required=True)
p.add_argument('--address', required=True)
p.add_argument('--peer-key', required=True)
p.add_argument('--old-remote', action='append', default=[])
p.add_argument('--old-prefix', action='append', default=[])
p.add_argument('--remote', default='10.250.1.7')
p.add_argument('--remote-prefix', default='10.250.1.7/32')
p.add_argument('--client', action='store_true')
p.add_argument('--port', type=int)
a = p.parse_args()
assert re.fullmatch(r'[A-Za-z0-9_-]{1,15}', a.interface)
ipaddress.ip_interface(a.address)
path = Path('/etc/wireguard') / (a.interface + '.conf')
original = path.read_text()
parts = re.split(r'(?m)^\[Peer\]\s*$', original)
assert len(parts) >= 2, 'Expected an existing WireGuard peer'
parts[0], count = re.subn(r'(?m)^Address\s*=.*$', 'Address = ' + a.address, parts[0])
assert count == 1, 'Expected exactly one Address setting'
matched = 0
for i in range(1, len(parts)):
    key = re.search(r'(?m)^PublicKey\s*=\s*(\S+)', parts[i])
    if not key or key.group(1) != a.peer_key:
        continue
    matched += 1
    allowed = re.search(r'(?m)^AllowedIPs\s*=\s*(.*)$', parts[i])
    assert allowed, 'Missing peer AllowedIPs'
    prefixes = [x.strip() for x in allowed.group(1).split(',')]
    prefixes = [x for x in prefixes if x not in a.old_prefix and x not in [v + '/32' for v in a.old_remote]]
    if not a.client:
        prefixes = [x for x in prefixes if x != a.remote + '/32']
    additions = ['10.250.0.0/16', '10.255.0.0/16'] if a.client else [a.remote_prefix]
    prefixes = list(dict.fromkeys(prefixes + additions))
    parts[i] = re.sub(r'(?m)^AllowedIPs\s*=.*$', 'AllowedIPs = ' + ', '.join(prefixes), parts[i])
    if a.client:
        parts[i] = re.sub(r'(?m)^PersistentKeepalive\s*=.*\n?', '', parts[i]).rstrip() + '\nPersistentKeepalive = 25\n'
assert matched == 1, 'Expected exactly one matching existing peer'
if a.client:
    assert len(parts) == 2, 'Client migration requires a dedicated single-peer interface'
    for chain in ('INPUT', 'FORWARD'):
        for prefix in ('10.250.0.0/16', '10.255.0.0/16'):
            rule = f'PostUp = iptables -C {chain} -s {prefix} -j ACCEPT || iptables -I {chain} 1 -s {prefix} -j ACCEPT'
            if rule not in parts[0]:
                parts[0] = parts[0].rstrip() + '\n' + rule + '\n'
    assert a.port and 1 <= a.port <= 65535
    rule = f'PostUp = iptables -C INPUT -s 62.60.216.73/32 -p udp --dport {a.port} -j ACCEPT || iptables -I INPUT 1 -s 62.60.216.73/32 -p udp --dport {a.port} -j ACCEPT'
    if rule not in parts[0]:
        parts[0] = parts[0].rstrip() + '\n' + rule + '\n'
result = parts[0].rstrip() + '\n' + ''.join('\n[Peer]\n' + part.strip('\n') + '\n' for part in parts[1:])
for old in a.old_remote:
    result = result.replace(old + '/32', a.remote + '/32')
if result != original:
    shutil.copy2(path, str(path) + '.before-network-migration')
    path.write_text(result)
    path.chmod(0o600)
    print('CONFIG_CHANGED')
else:
    print('CONFIG_UNCHANGED')
