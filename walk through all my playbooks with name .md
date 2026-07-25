walk through all my playbooks with name regex "^install_.+" and reorganize them.
All similar configuration (e.g., vars) sould be in one common config file.
Check if create_vm_instance is being used in any playbook
Remake install_sock5_proxy to make one single playbook with default params (passowrd socks5_proxy_password). And add a short exsamples on the top how to install with specific password and with no password
Convert ntp_server to role and include it into full.yml disbaled by default. Add variable for host kvm-server to enable it


Let's move all variables from inventory to group_vars and host_vars. I want keep in inventory only hostnames, their ip addresses and group membership


Convert install_* to one playboook "install_services.yaml" with params for all kind of containers. Mkae it according to ansible best practics. I don't know how it would be better, but seems there should be a role install_specific_service which will be callled many time from paybook install_services with params for every container required.
The list of containers should be specified in host  