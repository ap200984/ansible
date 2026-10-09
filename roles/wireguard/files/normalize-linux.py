#!/usr/bin/env python3
"""Consolidate Linux VPNs; private identities never leave the host."""
import argparse
import json
import re
from pathlib import Path
import shutil
import subprocess

CHECKPOINT = Path('/run/linux-wg-normalize')


def run(*args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def private_write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.touch(mode=0o600)
    path.write_text(text)
    path.chmod(0o600)


def key(path):
    return re.search(r'(?m)^PrivateKey\s*=\s*(\S+)', Path(path).read_text()).group(1)


def configuration(interface, private):
    lines = ['# Managed AmneziaWG OSPF mesh; normalized Linux interface' if interface['command'] == 'awg' else '# Managed normalized Linux interface', '[Interface]',
             'Address = ' + ', '.join(interface['addresses']), 'PrivateKey = ' + private,
             'ListenPort = ' + str(interface['port']), 'MTU = 1340', 'Table = off']
    for peer in interface['peers']:
        lines.append(f"PostUp = ip route replace {peer['address']}/32 dev %i src {peer['source']}")
    if interface['command'] == 'awg':
        lines += ['Jc = 4', 'Jmin = 40', 'Jmax = 80', 'S1 = 65', 'S2 = 107',
                  'H1 = 1723456781', 'H2 = 1723456782', 'H3 = 1723456783', 'H4 = 1723456784']
    for peer in interface['peers']:
        lines += ['', '[Peer]', 'PublicKey = ' + peer['public'],
                  'AllowedIPs = ' + ', '.join([peer['address'] + '/32', peer['loopback']] + peer.get('fixed', [])),
                  'PersistentKeepalive = 0']
        if peer.get('endpoint'):
            lines.append('Endpoint = ' + peer['endpoint'])
    return '\n'.join(lines) + '\n'


def routing(interface):
    return {'interface': interface['name'], 'command': interface['command'],
            'peers': {p['address']: p['public'] for p in interface['peers']},
            'loopbacks': {p['address']: p['loopback'] for p in interface['peers']},
            'fixed': {p['address']: p['fixed'] for p in interface['peers'] if p.get('fixed')}}


def prepare(spec):
    CHECKPOINT.mkdir(mode=0o700, exist_ok=True)
    for directory in ['wireguard', 'amnezia', 'frr']:
        source = Path('/etc') / directory
        target = CHECKPOINT / directory
        if source.exists() and not target.exists():
            shutil.copytree(source, target)
    for interface in spec['interfaces']:
        source = interface['key_source']
        if source.endswith('/wg2.conf') and not Path(source).exists():
            source = source.replace('/wg2.conf', '/wg1.conf')
        private = key(source)
        text = configuration(interface, private)
        private_write(CHECKPOINT / (interface['name'] + '.conf'), text)
        quick = 'awg-quick' if interface['command'] == 'awg' else 'wg-quick'
        # Parse configs without printing the resulting private-key contents.
        run(quick, 'strip', str(CHECKPOINT / (interface['name'] + '.conf')), stdout=subprocess.DEVNULL)
        private_write(CHECKPOINT / (interface['name'] + '-routing.json'), json.dumps(routing(interface), indent=2))
    private_write(CHECKPOINT / 'frr-candidate.conf', spec['frr'])
    run('vtysh', '-C', '-f', str(CHECKPOINT / 'frr-candidate.conf'))


def activate(spec):
    n = spec['number']
    subprocess.run(['systemctl', 'stop', 'amneziawg-routing'], check=False)
    subprocess.run(['systemctl', 'stop', 'wireguard-routing'], check=False)
    for name in (['wg-vds2', 'wg-vds6'] if n == 5 else ['wg1'] if n in [2, 6] else []):
        run('systemctl', 'disable', '--now', 'wg-quick@' + name)
    if n in [1, 8]:
        run('systemctl', 'stop', 'awg-quick@wg1')
        run('systemctl', 'disable', '--now', 'awg-quick@wg2')
    elif n == 5:
        run('systemctl', 'stop', 'awg-quick@wg1')
    # Recreate wg0 only where its two address ranges must be installed.
    if n in [2, 5, 6]:
        run('systemctl', 'stop', 'wg-quick@wg0')
    for interface in spec['interfaces']:
        name = interface['name']
        directory = Path('/etc/amnezia/amneziawg' if interface['command'] == 'awg' else '/etc/wireguard')
        private_write(directory / (name + '.conf'), (CHECKPOINT / (name + '.conf')).read_text())
        private_write(directory / 'routing.json', (CHECKPOINT / (name + '-routing.json')).read_text())
        if interface['command'] == 'awg':
            # Mesh role must read the same identity as the merged interface.
            private_write(directory / 'wg1.key', key(directory / 'wg1.conf') + '\n')
        service = ('awg-quick@' if interface['command'] == 'awg' else 'wg-quick@') + name
        run('systemctl', 'enable', '--now', service)
        manager = 'amneziawg-routing' if interface['command'] == 'awg' else 'wireguard-routing'
        run('systemctl', 'enable', '--now', manager)
    Path('/etc/frr/frr.conf').write_text(spec['frr'])
    run('systemctl', 'restart', 'frr')
    private_write(Path('/etc/wireguard/linux-normalized.enabled'), 'wg0 ordinary; wg1 Amnezia only\n')


def cleanup(spec):
    n = spec['number']
    paths = ['/etc/amnezia/amneziawg/wg2.conf']
    if n in [2, 6]:
        paths.append('/etc/wireguard/wg1.conf')
    if n == 5:
        paths += ['/etc/wireguard/wg-vds2.conf', '/etc/wireguard/wg-vds6.conf']
    for item in paths:
        Path(item).unlink(missing_ok=True)
    # Retired-interface firewall rules must not be restored at boot.
    import shlex
    for chain in ['INPUT', 'OUTPUT']:
        for line in subprocess.check_output(['iptables', '-S', chain], text=True).splitlines():
            args = shlex.split(line)
            if args[:1] == ['-A'] and 'wg2' in args:
                run('iptables', '-D', *args[1:])
    with open('/etc/iptables/rules.v4', 'w') as out:
        run('iptables-save', stdout=out)
    shutil.rmtree(CHECKPOINT)


def rollback(spec):
    n = spec['number']
    for service in ['wireguard-routing', 'amneziawg-routing', 'awg-quick@wg1', 'wg-quick@wg0']:
        subprocess.run(['systemctl', 'stop', service], check=False)
    subprocess.run(['systemctl', 'disable', 'wireguard-routing', 'linux-normalized-firewall'], check=False)
    for directory in ['wireguard', 'amnezia', 'frr']:
        source = CHECKPOINT / directory
        if source.exists():
            shutil.copytree(source, Path('/etc') / directory, dirs_exist_ok=True)
    run('systemctl', 'enable', '--now', 'wg-quick@wg0')
    if n in [1,5,8]:
        run('systemctl', 'enable', '--now', 'awg-quick@wg1', 'amneziawg-routing')
    if n in [1,8]:
        run('systemctl', 'enable', '--now', 'awg-quick@wg2')
    if n in [2,6]:
        run('systemctl', 'enable', '--now', 'wg-quick@wg1')
    if n == 5:
        run('systemctl', 'enable', '--now', 'wg-quick@wg-vds2', 'wg-quick@wg-vds6')
    run('systemctl', 'restart', 'frr')
    Path('/etc/wireguard/linux-normalized.enabled').unlink(missing_ok=True)
    Path('/etc/wireguard/routing.json').unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('mode', choices=['prepare', 'activate', 'cleanup', 'rollback'])
    parser.add_argument('--spec', default='/etc/wireguard/linux-normalized.json')
    args = parser.parse_args()
    spec = json.loads(Path(args.spec).read_text())
    globals()[args.mode](spec)


if __name__ == '__main__':
    main()
