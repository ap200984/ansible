#!/usr/bin/env python3
"""Seed preferred sources on existing OSPF loopbacks without pinning gateways."""
import argparse
import ipaddress
import json
import re
import subprocess

LOOPBACKS = ipaddress.ip_network('10.255.0.0/24')

def source_command(route, source):
    source = str(ipaddress.ip_address(source))
    if ipaddress.ip_address(source) not in LOOPBACKS:
        raise ValueError('Source must belong to the loopback network')
    destination = route.get('dst', 'default')
    if destination == 'default':
        return None
    network = ipaddress.ip_network(destination)
    if network.version != 4 or network.prefixlen != 32 or not network.subnet_of(LOOPBACKS):
        return None
    if route.get('prefsrc') == source:
        return None
    if route.get('type', 'unicast') != 'unicast':
        raise ValueError('Refusing to replace a non-unicast OSPF route')
    command = ['ip', '-4', 'route', 'replace', str(network), 'table', 'main', 'proto', 'ospf']
    if 'nhid' in route:
        nhid = int(route['nhid'])
        if nhid <= 0:
            raise ValueError('Invalid kernel nexthop identifier')
        command += ['nhid', str(nhid)]
    else:
        if route.get('nexthops'):
            raise ValueError('Multipath routes require a kernel nexthop identifier')
        device = route.get('dev', '')
        if not re.fullmatch(r'[a-zA-Z0-9_.:-]+', device):
            raise ValueError('Missing or invalid OSPF route interface')
        if 'gateway' in route:
            command += ['via', str(ipaddress.ip_address(route['gateway']))]
        command += ['dev', device]
    if route.get('metrics'):
        raise ValueError('Refusing to drop custom OSPF route metrics')
    if 'metric' in route:
        command += ['metric', str(int(route['metric']))]
    return command + ['src', source]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', required=True)
    args = parser.parse_args()
    addresses = json.loads(subprocess.check_output(['ip', '-j', '-4', 'address', 'show', 'dev', 'lo'], text=True))
    if not any(a.get('local') == args.source for interface in addresses for a in interface.get('addr_info', [])):
        raise ValueError('Requested source is not configured on lo')
    routes = json.loads(subprocess.check_output(['ip', '-j', '-4', 'route', 'show', 'table', 'main', 'proto', 'ospf'], text=True))
    commands = [cmd for route in routes if (cmd := source_command(route, args.source))]
    for command in commands:
        subprocess.run(command, check=True)
    print('LOOPBACK_SOURCES_UPDATED', len(commands))

if __name__ == '__main__':
    main()
