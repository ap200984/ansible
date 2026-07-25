# Create a KVM virtual machine

The `create_vm` role creates or starts exactly one KVM/libvirt virtual machine.
It downloads a Debian 12 cloud image, creates a qcow2 overlay, injects
cloud-init configuration, and configures a static IPv4 address.

## Manual creation

`vm_name` and `vm_ip_address` are obligatory and intentionally have no
defaults:

```bash
ansible-playbook -i inventory/kvm_server "00 create_vm.yaml" \
  -e vm_name=test-vm \
  -e vm_ip_address=10.9.1.50
```

Defaults:

- OS image and libvirt variant: Debian 12
- vCPUs: `1`
- RAM: `512` MB
- Disk: `10` GB
- Graphics: `none`
- Timezone: `UTC`
- Network source: `enp2s0`
- Prefix: `/24`
- Gateway: the VM address with its final octet replaced by `.1`
- DNS: `1.1.1.1` and `8.8.8.8`

Override resources when needed:

```bash
ansible-playbook -i inventory/kvm_server "00 create_vm.yaml" \
  -e vm_name=large-vm \
  -e vm_ip_address=10.9.1.51 \
  -e vm_vcpus=4 \
  -e vm_memory_mb=4096 \
  -e vm_disk_size_gb=40
```

## Kubernetes machines

The Kubernetes wrapper calls the same single-VM role once per entry in
`group_vars/k8s_k112.yml`:

```bash
ansible-playbook \
  -i inventory/k8s_k112 \
  -i inventory/kvm_server \
  k8s/01_create_k8s_cluster_machines.yaml
```

Machines are processed sequentially in mapping order.

## Required local files

- At least one public key under `ssh_public_keys/*.pub`.
- One non-empty password hash for each configured account under
  `passwd_hashes/`.

The role is idempotent by libvirt domain name. If the domain already exists,
disk and cloud-init creation are skipped and the role ensures it is running.
