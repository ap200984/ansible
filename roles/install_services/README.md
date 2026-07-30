# Container service installation

`install_services.yaml` is the single entry point for Docker services:

```shell
ansible-playbook -i inventory/vds5 install_services.yaml
ansible-playbook -i inventory/vds6 install_services.yaml --tags services
ansible-playbook -i inventory/vds6 install_services.yaml \
  -e socks5_proxy_password=''
```

Install or update only one selected service by using either its short tag or
its namespaced tag:

```shell
ansible-playbook -i inventory/k16_k112_server 02_deploy_services.yaml \
  --tags owncloud
ansible-playbook -i inventory/k16_k112_server 02_deploy_services.yaml \
  --tags services:owncloud
```

The `services` tag continues to install or update every service selected for
the host.

Hosts that need containers select their desired services with
`service_containers` in `host_vars/<inventory_hostname>.yml`. The role defaults
to an empty list, so hosts without container services need no host-vars file or
empty override. Container definitions and defaults live in
`defaults/main.yaml`; per-service preparation and post-install work lives in
small task files under `tasks/`.

The order in `service_containers` is significant for dependent services. For
example, PostgreSQL must precede the Zabbix backend and frontend, and Certbot
must precede NGINX.

Certbot bootstraps a wildcard certificate only when one is not already present.
It requires `domain` in host vars and the existing Vault-backed Reg.ru and
Let's Encrypt secret files.

After a successful renewal, Certbot touches
`/etc/letsencrypt/.nginx-reload`. NGINX watches that marker through the shared
read-only certificate volume and reloads itself within one minute. This does
not require host cron, the Docker socket, or privileged container access.
