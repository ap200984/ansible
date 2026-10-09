#!/usr/bin/env python3
"""Move selected AWG links to ordinary WG, keeping keys private on each host."""
import argparse
import json
from pathlib import Path
import re
import subprocess

AWG = Path('/etc/amnezia/amneziawg')
WG = Path('/etc/wireguard')
FRR = Path('/etc/frr/frr.conf')
ENDPOINTS = {2: '38.247.137.237', 5: '217.144.189.206', 6: '195.245.239.82'}
PORTS = {2: 56698, 5: 56695, 6: 56696}


def private_key(path):
    return re.search(r'(?m)^PrivateKey\s*=\s*(\S+)', path.read_text()).group(1)


def write_private(path, content):
    path.touch(mode=0o600)
    path.write_text(content)
    path.chmod(0o600)


def config(address, local_port, private, public, endpoint, remote_address, loopback=None):
    return f'''# Managed ordinary WireGuard replacement for selected AWG link.
[Interface]
Address = {address}/24
PrivateKey = {private}
ListenPort = {local_port}
MTU = 1340
Table = off
PostUp = ip route replace {remote_address}/32 dev %i src {address}
''' + (f'PostUp = ip address replace {loopback}/32 dev lo\n' if loopback else '') + f'''
[Peer]
PublicKey = {public}
Endpoint = {endpoint}
AllowedIPs = 10.0.0.0/8, 224.0.0.5/32
PersistentKeepalive = 0
'''


def ospf_interface(name, address, cost):
    return f'''interface {name}
 ip ospf area 0.0.0.0 {address}
 ip ospf network point-to-point
 ip ospf cost {cost}
 ip ospf hello-interval 60
 ip ospf dead-interval 240
!\n'''


def replace_interface(text, name, replacement):
    pattern = r'(?ms)^interface ' + re.escape(name) + r'\n.*?^!\n'
    if re.search(pattern, text):
        return re.sub(pattern, lambda _: replacement, text)
    return text.replace('router ospf\n', replacement + 'router ospf\n')


def save_frr(text):
    candidate = Path('/run/wg-revert-20261005/frr-candidate.conf')
    candidate.write_text(text)
    subprocess.run(['vtysh', '-C', '-f', str(candidate)], check=True)
    FRR.write_text(text)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('mode', choices=['hub-prepare', 'leaf-prepare', 'leaf-frr', 'hub-trim', 'chr-prepare', 'chr-frr'])
    p.add_argument('--number', type=int, choices=[2, 5, 6], required=True)
    p.add_argument('--peer-number', type=int, choices=[2, 6])
    p.add_argument('--peer-key')
    p.add_argument('--peer-keys', default='{}')
    a = p.parse_args()
    n = a.number
    if a.mode == 'hub-prepare':
        assert n == 5
        keys = json.loads(a.peer_keys)
        private = private_key(AWG / 'wg1.conf')
        text = FRR.read_text()
        for peer in (2, 6):
            write_private(WG / f'wg-vds{peer}.conf', config(
                '10.250.2.5', 56710 + peer, private, keys[str(peer)],
                f'{ENDPOINTS[peer]}:56702', f'10.250.2.{peer}'))
            text = replace_interface(text, f'wg-vds{peer}', ospf_interface(f'wg-vds{peer}', '10.250.2.5', 200))
        save_frr(text)
    elif a.mode == 'leaf-prepare':
        assert n in (2, 6) and a.peer_key
        write_private(WG / 'wg1.conf', config(
            f'10.250.2.{n}', 56702, private_key(AWG / 'wg1.conf'), a.peer_key,
            f'{ENDPOINTS[5]}:{56710 + n}', '10.250.2.5'))
    elif a.mode == 'leaf-frr':
        text = replace_interface(FRR.read_text(), 'wg1', ospf_interface('wg1', f'10.250.2.{n}', 200))
        text = re.sub(r'(?m)^ neighbor 10\.250\.2\.5 .*\n', '', text)
        save_frr(text)
    elif a.mode == 'hub-trim':
        assert n == 5 and a.peer_number and a.peer_key
        peer = a.peer_number
        path = AWG / 'wg1.conf'
        parts = re.split(r'(?m)^\[Peer\]\s*$', path.read_text())
        parts[0] = re.sub(r'(?m)^PostUp = .*10\.250\.2\.' + str(peer) + r'/32.*\n?', '', parts[0])
        parts = [parts[0]] + [part for part in parts[1:]
                 if not re.search(r'(?m)^PublicKey\s*=\s*' + re.escape(a.peer_key) + r'\s*$', part)]
        write_private(path, parts[0].rstrip() + '\n' + ''.join('\n[Peer]\n' + x.strip() + '\n' for x in parts[1:]))
        routing = AWG / 'routing.json'
        data = json.loads(routing.read_text())
        data['peers'].pop(f'10.250.2.{peer}', None)
        write_private(routing, json.dumps(data, indent=2) + '\n')
        subprocess.run(['awg', 'set', 'wg1', 'peer', a.peer_key, 'remove'], check=True)
        text = re.sub(r'(?m)^ neighbor 10\.250\.2\.' + str(peer) + r' .*\n', '', FRR.read_text())
        save_frr(text)
        subprocess.run(['vtysh', '-c', 'configure terminal', '-c', 'router ospf', '-c', f'no neighbor 10.250.2.{peer}'], check=True)
        subprocess.run(['ip', 'route', 'replace', f'10.250.2.{peer}/32', 'dev', f'wg-vds{peer}', 'src', '10.250.2.5'], check=True)
    elif a.mode == 'chr-prepare':
        assert a.peer_key
        write_private(WG / 'wg0.conf', config(
            f'10.250.1.{n}', PORTS[n], private_key(AWG / 'wg2.conf'), a.peer_key,
            f'62.60.216.73:{PORTS[n]}', '10.250.1.7', f'10.255.0.{n}'))
    elif a.mode == 'chr-frr':
        text = replace_interface(FRR.read_text(), 'wg2', '')
        text = replace_interface(text, 'wg0', ospf_interface('wg0', f'10.250.1.{n}', 1001 if n == 5 else 1000))
        text = re.sub(r'(?m)^ neighbor 10\.250\.1\.7 .*\n', '', text)
        save_frr(text)


if __name__ == '__main__':
    main()
