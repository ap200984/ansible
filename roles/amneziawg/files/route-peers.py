#!/usr/bin/env python3
"""Keep AmneziaWG cryptokey routes aligned with FRR's single-path OSPF FIB.

On a shared WireGuard interface, the packet destination (not its next hop)
selects the peer. Each prefix must have exactly one owner. This reconciler
assigns learned prefixes to their OSPF next-hop peer and preserves direct
neighbor /32s for unicast hellos. It never creates Linux destination routes.
"""
import argparse
import ipaddress
import json
from pathlib import Path
import subprocess
import time


def desired_prefixes(peers, routes, loopbacks=None, fixed=None):
    loopbacks = loopbacks or {}
    fixed = fixed or {}
    owners = {address + '/32': key for address, key in peers.items()}
    for address, key in peers.items():
        owners[loopbacks.get(address, '10.255.0.' + address.rsplit('.', 1)[1] + '/32')] = key
    for route in routes:
        destination = route.get('dst', '')
        if destination == 'default' or not destination:
            continue
        network = ipaddress.ip_network(destination)
        if not network.subnet_of(ipaddress.ip_network('10.0.0.0/8')):
            continue
        hops = route.get('nexthops', [route])
        candidates = [hop.get('gateway') for hop in hops if hop.get('gateway') in peers]
        if len(set(candidates)) > 1:
            raise ValueError('ECMP requires distinct per-peer interfaces; OSPF maximum-paths must remain 1')
        if candidates and destination not in {address + '/32' for address in peers}:
            owners[str(network)] = peers[candidates[0]]
    for address, prefixes in fixed.items():
        for prefix in prefixes:
            owners[prefix] = peers[address]
    return {key: sorted(prefix for prefix, owner in owners.items() if owner == key)
            for key in peers.values()}


def reconcile(config):
    interface = config['interface']
    routes = json.loads(subprocess.check_output(
        ['ip', '-j', '-4', 'route', 'show', 'dev', interface, 'proto', 'ospf'], text=True))
    wanted = desired_prefixes(config['peers'], routes, config.get('loopbacks'), config.get('fixed'))
    command = config.get('command', 'awg')
    current = {}
    output = subprocess.check_output([command, 'show', interface, 'allowed-ips'], text=True)
    for line in output.splitlines():
        key, prefixes = line.split('\t', 1)
        current[key] = sorted(prefixes.replace(',', ' ').split()) if prefixes != '(none)' else []
    # One set command installs the complete new ownership map. Adding/moving
    # prefixes can steal ownership, so subsequent removals must not clear a
    # prefix that another peer has just acquired.
    if current != wanted:
        args = [command, 'set', interface]
        for key, prefixes in wanted.items():
            args += ['peer', key, 'allowed-ips', ','.join(prefixes)]
        subprocess.run(args, check=True)
        print('AWG_ALLOWED_IPS_UPDATED', flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--config', default='/etc/amnezia/amneziawg/routing.json')
    parser.add_argument('--once', action='store_true')
    args = parser.parse_args()
    config = json.loads(Path(args.config).read_text())
    while True:
        try:
            reconcile(config)
        except (OSError, ValueError, subprocess.CalledProcessError) as error:
            if args.once:
                raise
            print('AWG_ROUTE_RECONCILE_ERROR: ' + str(error), flush=True)
        if args.once:
            return
        time.sleep(1)


if __name__ == '__main__':
    main()
