# create_etcd_cluster

Create a plain HTTP etcd cluster on trusted internal hosts.

This role does not configure TLS certificates or firewall rules.

## Run

```bash
ansible-playbook -i inventory/k8s_k112 create_etcd_cluster.yaml \
  -e hosts=etcd1,etcd2,etcd3
```

The hosts must exist in inventory. If a host has an `ip_address` variable, the
role uses it for peer and client advertise URLs. Otherwise it uses `ansible_host`,
then falls back to the inventory hostname.

## Useful variables

- `etcd_version`: etcd release to install. Default: `v3.5.17`.
- `etcd_client_port`: client port. Default: `2379`.
- `etcd_peer_port`: peer port. Default: `2380`.
- `etcd_data_dir`: data directory. Default: `/var/lib/etcd`.
- `etcd_cluster_token`: initial cluster token. Default: `etcd-cluster`.

## Check

From one cluster node:

```bash
etcdctl --endpoints=http://127.0.0.1:2379 endpoint health
etcdctl --endpoints=http://127.0.0.1:2379 member list
```

