#!/usr/bin/env python3
"""Reset only selected IPv4 sessions that still use the pre-GRE NAT path."""
import argparse
import ipaddress
import json
import re
import subprocess

def stale_connections(prefixes, connections, gre_address):
    networks = []
    for prefix in prefixes:
        try:
            network = ipaddress.ip_network(prefix['address'])
        except (KeyError, ValueError):
            continue  # Static FQDN entries have separate dynamic IP entries.
        if network.version == 4:
            networks.append(network)
    stale = []
    for connection in connections:
        try:
            destination = ipaddress.ip_address(connection['dst-address'].split(':')[0])
        except (KeyError, ValueError):
            continue
        if not any(destination in network for network in networks):
            continue
        if connection.get('srcnat') is True and 'reply-dst-address' not in connection:
            raise ValueError('NAT return address missing from detailed connection data')
        reply_destination = str(connection.get('reply-dst-address', '')).split(':')[0]
        if reply_destination == gre_address:
            continue
        entry_id = connection.get('.id', '')
        if not re.fullmatch(r'\*[0-9A-Fa-f]+', entry_id):
            raise ValueError('Invalid connection identifier')
        stale.append(entry_id)
    return stale

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--ssh', required=True)
    parser.add_argument('--gre-address', required=True)
    parser.add_argument('--address-lists', nargs='+', default=['google_ips'])
    args = parser.parse_args()
    if not all(re.fullmatch(r'[a-zA-Z0-9_-]+', name) for name in args.address_lists):
        parser.error('Invalid address list name')
    transport = json.loads(args.ssh)
    def query(command):
        result = subprocess.run(transport + [command], capture_output=True, text=True, check=True, timeout=30)
        return json.loads(result.stdout)
    selector = ' or '.join('list=' + name for name in args.address_lists)
    prefixes = query(':put [:serialize to=json [/ip firewall address-list print as-value where ' + selector + ']];')
    connections = query(':put [:serialize to=json [/ip firewall connection print detail as-value]];')
    stale = stale_connections(prefixes, connections, args.gre_address)
    for offset in range(0, len(stale), 50):
        result = subprocess.run(transport + ['/ip firewall connection remove ' + ','.join(stale[offset:offset+50])], capture_output=True, text=True, check=True, timeout=30)
        if 'failure:' in result.stdout or 'syntax error' in result.stdout:
            raise RuntimeError('Targeted connection reset failed')
    print('RESET_OLD_GOOGLE_SESSIONS', len(stale))
