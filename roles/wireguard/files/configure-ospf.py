#!/usr/bin/env python3
"""Preserve existing keys/peers while configuring prefixes and OSPF route ownership."""
import argparse
import ipaddress
import json
from pathlib import Path
import re
import shutil
import subprocess

p = argparse.ArgumentParser()
p.add_argument('--interface', required=True)
p.add_argument('--address', required=True)
p.add_argument('--mtu', type=int, default=1420)
p.add_argument('--networks', required=True)
p.add_argument('--loopback', required=True)
p.add_argument('--peers', default='{}')
a = p.parse_args()
assert re.fullmatch(r'[A-Za-z0-9_-]{1,15}', a.interface)
ipaddress.ip_interface(a.address)
ipaddress.ip_interface(a.loopback)
assert 1280 <= a.mtu <= 1500
networks = json.loads(a.networks)
ownership = json.loads(a.peers)
for prefix in networks:
    ipaddress.ip_network(prefix)
path = Path('/etc/wireguard') / (a.interface + '.conf')
original = path.read_text()
parts = re.split(r'(?m)^\[Peer\]\s*$', original)
assert len(parts) > 1
old_prefixes = set()
parts[0], count = re.subn(r'(?m)^Address\s*=.*$', 'Address = ' + a.address, parts[0])
assert count == 1
if re.search(r'(?m)^MTU\s*=', parts[0]):
    parts[0] = re.sub(r'(?m)^MTU\s*=.*$', 'MTU = ' + str(a.mtu), parts[0])
else:
    parts[0] = parts[0].rstrip() + '\nMTU = ' + str(a.mtu) + '\n'
if re.search(r'(?m)^Table\s*=', parts[0]):
    parts[0] = re.sub(r'(?m)^Table\s*=.*$', 'Table = off', parts[0])
else:
    parts[0] = parts[0].rstrip() + '\nTable = off\n'
loopback_rule = 'PostUp = ip address replace ' + a.loopback + ' dev lo'
if loopback_rule not in parts[0]:
    parts[0] += loopback_rule + '\n'
# Old transport source routes remain useful; old broad permission rules do not.
parts[0] = re.sub(r'(?m)^PostUp = iptables -C (?:INPUT|FORWARD) -s 10\.(?:250|255)\.0\.0/16 .*\n?', '', parts[0])
for i in range(1, len(parts)):
    key = re.search(r'(?m)^PublicKey\s*=\s*(\S+)', parts[i]).group(1)
    allowed = re.search(r'(?m)^AllowedIPs\s*=\s*(.*)$', parts[i])
    assert allowed
    old = [x.strip() for x in allowed.group(1).split(',')]
    old_prefixes.update(old)
    if len(parts) == 2:
        # Retain unrelated LAN/PPP destinations, but replace broad tunnel ranges.
        extra = [x for x in old if not any(ipaddress.ip_network(x).overlaps(ipaddress.ip_network(n)) for n in networks)]
        prefixes = networks + extra
    else:
        assert key in ownership, 'Missing explicit shared-interface peer ownership'
        prefixes = ownership[key]
    parts[i] = re.sub(r'(?m)^AllowedIPs\s*=.*$', 'AllowedIPs = ' + ', '.join(dict.fromkeys(prefixes)), parts[i])
result = parts[0].rstrip() + '\n' + ''.join('\n[Peer]\n' + part.strip('\n') + '\n' for part in parts[1:])
if result != original:
    shutil.copy2(path, str(path) + '.before-ospf')
    path.write_text(result)
    path.chmod(0o600)
    print('CONFIG_CHANGED')
# wg syncconf changes peer permissions without bouncing established tunnels.
stripped = subprocess.check_output(['wg-quick', 'strip', a.interface])
subprocess.run(['wg', 'syncconf', a.interface, '/dev/stdin'], input=stripped, check=True)
subprocess.run(['ip', 'address', 'replace', a.address, 'dev', a.interface], check=True)
subprocess.run(['ip', 'link', 'set', 'dev', a.interface, 'mtu', str(a.mtu)], check=True)
subprocess.run(['ip', 'address', 'replace', a.loopback, 'dev', 'lo'], check=True)
address = a.address.split('/')[0]
for length in (21, 32):
    subprocess.run(['ip', 'address', 'del', address + '/' + str(length), 'dev', a.interface], capture_output=True)
# Remove only wg-quick link routes; OSPF routes have global scope and are untouched.
for prefix in old_prefixes | set(networks):
    if prefix != str(ipaddress.ip_interface(a.address).network):
        subprocess.run(['ip', 'route', 'del', prefix, 'dev', a.interface, 'scope', 'link', 'proto', 'boot'], capture_output=True)
