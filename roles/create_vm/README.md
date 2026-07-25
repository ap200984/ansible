# create_vm role

Creates or starts one KVM/libvirt virtual machine.

Required variables:

- `vm_name`
- `vm_ip_address`

The resource, image, network, cloud-init user, and storage defaults are
documented in `defaults/main.yaml`. Callers may override any of them through
normal Ansible variable precedence.
