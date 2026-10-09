#!/usr/bin/env python3
"""Remove only audited obsolete VPN configuration and network backups."""
import argparse
from pathlib import Path
import shutil
import subprocess

p = argparse.ArgumentParser()
p.add_argument('--number', type=int, choices=[2, 5, 6], required=True)
a = p.parse_args()
def remove(path):
    path = Path(path)
    if path.is_dir():
        shutil.rmtree(path)
    elif path.exists() or path.is_symlink():
        path.unlink()
    else:
        return
    print('Removed', path)

# These services are obsolete on all three converted CHR endpoints.
subprocess.run(['systemctl', 'disable', '--now', 'chr-native-awg-firewall'], check=False)
for path in ['/etc/amnezia/amneziawg/wg2.conf', '/etc/amnezia/amneziawg/chr-native.enabled',
             '/usr/local/sbin/chr-native-awg-firewall', '/etc/systemd/system/chr-native-awg-firewall.service']:
    remove(path)
if a.number in (2, 6):
    remove('/etc/amnezia/amneziawg')
    remove('/usr/local/sbin/amneziawg-route-peers')
    remove('/etc/systemd/system/amneziawg-routing.service')

# Remove exact audited migration checkpoints; never broad /root contents.
for path in ['/root/before-chr-awg-20261005', '/root/before-chr-native-awg-20261005',
             '/run/wg-revert-20261005']:
    remove(path)
for directory in ['/etc/wireguard', '/etc/frr', '/etc/iptables', '/etc/sysctl.d']:
    root = Path(directory)
    if not root.exists():
        continue
    for path in root.iterdir():
        if path.is_file() and (path.name.endswith('~') or '.before-' in path.name
                              or '.retired' in path.name or path.suffix in ('.bak', '.backup')):
            remove(path)

# Delete precise retired-interface firewall rules, preserving Docker and NAT policy.
for chain in ['INPUT', 'OUTPUT']:
    rules = subprocess.check_output(['iptables', '-S', chain], text=True).splitlines()
    import shlex
    for line in rules:
        args = shlex.split(line)
        if args[:1] != ['-A']:
            continue
        obsolete = 'chr-native-awg' in args or ('wg2' in args and 'ospf' in args)
        if a.number == 5 and '--dport' in args and args[args.index('--dport') + 1] == '56702':
            obsolete |= any(x in args for x in ['38.247.137.237/32', '195.245.239.82/32'])
        if obsolete:
            subprocess.run(['iptables', '-D'] + args[1:], check=True)
subprocess.run(['systemctl', 'daemon-reload'], check=True)
with open('/etc/iptables/rules.v4', 'w') as out:
    subprocess.run(['iptables-save'], stdout=out, check=True)
