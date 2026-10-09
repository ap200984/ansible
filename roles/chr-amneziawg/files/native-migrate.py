#!/usr/bin/env python3
"""Prepare native CHR AWG without printing or transferring private keys."""
import argparse
from pathlib import Path
import re
import subprocess


def prepare(original, peer_key, number):
    parts = re.split(r'(?m)^\[Peer\]\s*$', original)
    key = re.search(r'(?m)^PrivateKey\s*=\s*(\S+)', parts[0]).group(1)
    peers = [part for part in parts[1:]
             if re.search(r'(?m)^PublicKey\s*=\s*' + re.escape(peer_key) + r'\s*$', part)]
    if len(peers) != 1:
        raise ValueError('Expected exactly one existing CHR peer')
    header = re.sub(r'(?m)^PostUp\s*=.*10\.250\.1\.7(?:/32)?\b.*\n?', '', parts[0])
    plain = header.rstrip() + '\n' + ''.join(
        '\n[Peer]\n' + part.strip() + '\n' for part in parts[1:] if part not in peers)
    native = f'''# Managed native AmneziaWG CHR link; original wg0 identity preserved.
[Interface]
Address = 10.250.1.{number}/24
PrivateKey = {key}
ListenPort = 56707
MTU = 1340
Table = off
PostUp = ip route replace 10.250.1.7/32 dev %i src 10.250.1.{number}
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
PublicKey = {peer_key}
AllowedIPs = 10.0.0.0/8, 224.0.0.5/32
PersistentKeepalive = 0
'''
    return plain, native


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--peer', required=True)
    parser.add_argument('--number', type=int, required=True)
    args = parser.parse_args()
    assert args.number in (1, 2, 5, 6, 8)
    plain_path = Path('/etc/wireguard/wg0.conf')
    plain, native = prepare(plain_path.read_text(), args.peer, args.number)
    native_path = Path('/etc/amnezia/amneziawg/wg2.conf')
    native_path.touch(mode=0o600)
    native_path.write_text(native)
    native_path.chmod(0o600)
    plain_path.write_text(plain)
    plain_path.chmod(0o600)
    subprocess.run(['wg', 'set', 'wg0', 'peer', args.peer, 'remove'], check=True)


if __name__ == '__main__':
    main()
