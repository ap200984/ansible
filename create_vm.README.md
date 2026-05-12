# create_vm.yaml

Create and start a Debian 12 KVM/libvirt virtual machine from a cloud image.
The playbook downloads the base image, creates a qcow2 overlay disk, injects
cloud-init data, configures a static IP address, starts the VM, and waits for SSH.

## Requirements

- Run the playbook against a KVM/libvirt host.
- The target host should be Debian-based, or already have equivalent packages:
  `libguestfs-tools`, `libvirt-clients`, `qemu-utils`, and `virtinst`.
- At least one public key must exist in `ssh_public_keys/*.pub`.
- The Ansible user must be able to become root on the KVM host.

## Required variables

Pass these variables every time:

- `vm_name`: libvirt domain name and VM hostname.
- `vm_ip_address`: static IPv4 address assigned inside the VM.

Optional but commonly used:

- `vm_user`: user shown in the final SSH connection message. Default: `ansible`.
- `vm_memory_mb`: RAM in MB. Default: `2048`.
- `vm_vcpus`: number of vCPUs. Default: `2`.
- `vm_disk_size_gb`: disk size in GB. Default: `20`.
- `vm_timezone`: timezone inside the VM. Default: `UTC`.
- `vm_network_source`: host network interface used by libvirt direct networking. Default: `enp2s0`.
- `vm_netmask_prefix`: network prefix. Default: `24`.
- `vm_gateway`: gateway IP. Default: first three octets of `vm_ip_address` plus `.1`.
- `vm_dns_servers`: DNS servers. Default: `1.1.1.1`, `8.8.8.8`.

## Basic launch

```bash
ansible-playbook -i inventory/kvm_server create_vm.yaml \
  -e vm_name=test-vm-01 \
  -e vm_ip_address=10.9.0.201
```

After the playbook finishes, connect with:

```bash
ssh ansible@10.9.0.201
```

## Launch with custom resources

```bash
ansible-playbook -i inventory/kvm_server create_vm.yaml \
  -e vm_name=pgadmin-vm \
  -e vm_ip_address=10.9.0.202 \
  -e vm_memory_mb=4096 \
  -e vm_vcpus=4 \
  -e vm_disk_size_gb=40 \
  -e vm_timezone=Europe/Madrid
```

## Launch on another network interface

Use this when the KVM host bridge/direct interface is not `enp2s0`.

```bash
ansible-playbook -i inventory/kvm_server create_vm.yaml \
  -e vm_name=web-vm-01 \
  -e vm_ip_address=192.168.50.20 \
  -e vm_network_source=br0 \
  -e vm_network_source_mode=bridge \
  -e vm_gateway=192.168.50.1 \
  -e '{"vm_dns_servers":["192.168.50.1","1.1.1.1"]}'
```

## Launch without waiting for SSH

Useful if the VM network is not reachable from the machine running Ansible.

```bash
ansible-playbook -i inventory/kvm_server create_vm.yaml \
  -e vm_name=isolated-vm \
  -e vm_ip_address=10.9.0.203 \
  -e vm_wait_for_ssh=false
```

## Notes

- The playbook is idempotent for existing libvirt domains: if `vm_name` already
  exists, it will skip image creation and make sure the VM is running.
- The default users are `root`, `ansible`, `user`, and `apopov`.
- Password hashes for the default users are read from `passwd_hashes/root`,
  `passwd_hashes/ansible`, `passwd_hashes/user`, and `passwd_hashes/apopov`.
  These files must exist and contain one non-empty single-line hash each.
- All public keys from `ssh_public_keys/*.pub` are added to each VM user's
  `authorized_keys`.
- VM images are stored in `/var/lib/libvirt/images` by default.
- Cloud-init seed files are stored in
  `/var/lib/libvirt/images/cloud-init/<vm_name>` by default.
- The default cloud image is Debian 12:
  `https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2`.



---
ansible-playbook -i inventory/kvm_server create_vm.yaml \
  -e vm_name=etcd1 \
  -e vm_ip_address=10.9.1.11 \
  -e vm_memory_mb=512 \
  -e vm_vcpus=1 \
  -e vm_disk_size_gb=10


### ansible-playbook -i inventory/kvm_server create_vm.yaml  -e vm_name=etcd2 -e vm_ip_address=10.9.1.12 -e vm_memory_mb=512 -e vm_vcpus=1 -e vm_disk_size_gb=10
### ansible-playbook -i inventory/k8s_k112 create_etcd_cluster.yaml -e hosts=etcd1,etcd2,etcd3
### ansible-playbook -i inventory/k16_k112_server ntp_server.yml
### ansible-playbook -i inventory/k8s_k112 new_machine.yml


sudo virsh destroy etcd1   && sudo virsh undefine etcd1   --remove-all-storage
sudo virsh destroy etcd2   && sudo virsh undefine etcd2   --remove-all-storage
sudo virsh destroy etcd3   && sudo virsh undefine etcd3   --remove-all-storage
sudo virsh destroy master1 && sudo virsh undefine master1 --remove-all-storage
sudo virsh destroy master2 && sudo virsh undefine master2 --remove-all-storage
sudo virsh destroy worker1 && sudo virsh undefine worker1 --remove-all-storage
sudo virsh destroy worker2 && sudo virsh undefine worker2 --remove-all-storage
sudo virsh destroy worker3 && sudo virsh undefine worker3 --remove-all-storage


ansible-playbook -i inventory/kvm_server create_vm.yaml  -e vm_name=etcd1 -e vm_ip_address=10.9.1.11 -e vm_memory_mb=512 -e vm_vcpus=1 -e vm_disk_size_gb=10
ansible-playbook -i inventory/kvm_server create_vm.yaml  -e vm_name=etcd2 -e vm_ip_address=10.9.1.12 -e vm_memory_mb=512 -e vm_vcpus=1 -e vm_disk_size_gb=10
ansible-playbook -i inventory/kvm_server create_vm.yaml  -e vm_name=etcd3 -e vm_ip_address=10.9.1.13 -e vm_memory_mb=512 -e vm_vcpus=1 -e vm_disk_size_gb=10
ansible-playbook -i inventory/kvm_server create_vm.yaml  -e vm_name=master1 -e vm_ip_address=10.9.1.21 -e vm_memory_mb=2048 -e vm_vcpus=1 -e vm_disk_size_gb=10
ansible-playbook -i inventory/kvm_server create_vm.yaml  -e vm_name=master2 -e vm_ip_address=10.9.1.22 -e vm_memory_mb=2048 -e vm_vcpus=1 -e vm_disk_size_gb=10
ansible-playbook -i inventory/kvm_server create_vm.yaml  -e vm_name=worker1 -e vm_ip_address=10.9.1.31 -e vm_memory_mb=2048 -e vm_vcpus=1 -e vm_disk_size_gb=10
ansible-playbook -i inventory/kvm_server create_vm.yaml  -e vm_name=worker2 -e vm_ip_address=10.9.1.32 -e vm_memory_mb=2048 -e vm_vcpus=1 -e vm_disk_size_gb=10
ansible-playbook -i inventory/kvm_server create_vm.yaml  -e vm_name=worker3 -e vm_ip_address=10.9.1.33 -e vm_memory_mb=2048 -e vm_vcpus=1 -e vm_disk_size_gb=10

## Launch K8s cluster VMs from inventory k8s_k112

Use the inventory file `inventory/k8s_k112` together with `inventory/kvm_server` and the new `k8s_cluster.yaml` wrapper.

```bash
ansible-playbook -i inventory/k8s_k112 -i inventory/kvm_server k8s_cluster.yaml -e vm_hosts=etcd1,etcd2,etcd3
```

To create all defined cluster VMs:

```bash
ansible-playbook -i inventory/k8s_k112 -i inventory/kvm_server k8s_cluster.yaml
```
