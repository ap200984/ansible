# ansible

This is my awesome ansible repository!

# add new key on main machine (if not exist):
ssh-keygen -t ed25519 -C "ansible"
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/alexander/.ssh/id_ed25519): /home/alexander/.ssh/ansible
Enter passphrase (empty for no passphrase): [empty]
Enter same passphrase again: [empty]

# use separate username for ansible on all hosts
server1$ sudo useradd -s /bin/bash -m -G sudo ansible
server1$ sudo passwd ansible
server2$ sudo useradd -s /bin/bash -m -G sudo ansible
server2$ sudo passwd ansible
server3$ sudo useradd -s /bin/bash -m -G sudo ansible
server3$ sudo passwd ansible

# copy key to all hosts
ssh-copy-id -i ~/.ssh/ansible.pub ansible@10.9.0.156
ssh-copy-id -i ~/.ssh/ansible.pub ansible@10.9.0.157
ssh-copy-id -i ~/.ssh/ansible.pub ansible@10.9.0.160

# check availibility
ansible all -i inventory -m ping

# run single command 
ansible all -i inventory -a "sudo iptables -S"

