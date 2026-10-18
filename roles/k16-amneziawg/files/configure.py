#!/usr/bin/env python3
"""Build a dedicated native K16 AWG link with the existing Linux identity."""
import argparse
from pathlib import Path
import re
import subprocess

K16_KEY = '09+N44Dl/exqOELQAoECIev+VASLf3ki8lxJFDf10Bw='

def prepare(original, number):
    key = re.search(r'(?m)^PrivateKey\s*=\s*(\S+)', original).group(1)
    return f'''# Managed K16 AmneziaWG transport; OSPF owns destinations.
[Interface]
Address = 10.250.6.{number}/24
PrivateKey = {key}
ListenPort = 56708
MTU = 1340
Table = off
PostUp = ip route replace 10.250.6.112/32 dev %i src 10.250.6.{number}
Jc = 4
Jmin = 40
Jmax = 80
S1 = 65
S2 = 107
H1 = 1723456781
H2 = 1723456782
H3 = 1723456783
H4 = 1723456784

[Peer]
PublicKey = {K16_KEY}
AllowedIPs = 10.0.0.0/8, 224.0.0.5/32
PersistentKeepalive = 0
'''

def remove_peer(original):
    parts = re.split(r'(?m)^\[Peer\]\s*$', original)
    result = parts[0]
    result = re.sub(r'(?m)^PostUp\s*=.*10\.250\.1\.112/32.*\n?', '', result)
    result = result.rstrip() + '\n'
    for part in parts[1:]:
        if re.search(r'(?m)^PublicKey\s*=\s*' + re.escape(K16_KEY) + r'\s*$', part):
            continue
        result += '\n[Peer]\n' + part.strip() + '\n'
    return result

if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('action', choices=['prepare', 'remove-plain'])
    p.add_argument('--number', type=int, choices=[1,8], required=True)
    a = p.parse_args()
    source = Path('/etc/wireguard/wg0.conf')
    if a.action == 'prepare':
        target = Path('/etc/amnezia/amneziawg/wg3.conf')
        result = prepare(source.read_text(), a.number)
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists() or target.read_text() != result:
            target.touch(mode=0o600); target.write_text(result); target.chmod(0o600)
            print('CONFIG_CHANGED')
    else:
        original = source.read_text(); result = remove_peer(original)
        if original != result:
            source.write_text(result); source.chmod(0o600); print('CONFIG_CHANGED')
        subprocess.run(['wg','set','wg0','peer',K16_KEY,'remove'],check=True)
        subprocess.run(['ip','route','del','10.250.1.112/32','dev','wg0','proto','boot'],capture_output=True)
