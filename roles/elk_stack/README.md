# ELK stack role

Runs Elasticsearch, Logstash, and Kibana as three Docker containers. Logstash
accepts Beats events on TCP port `5044`, Elasticsearch uses `9200`, and Kibana
uses `5601`.

Security is disabled, so expose these ports only on a trusted network or
protect them with firewall rules and a reverse proxy.

To make Kibana download Fleet integrations through the same authenticated
forward proxy as Nexus, enable:

```yaml
elk_kibana_integrations_use_proxy: true
```

The role then reuses `squid_endpoint`, `squid_user`, and `squid_pass`. They can
instead be overridden with `elk_kibana_integrations_proxy_endpoint`,
`elk_kibana_integrations_proxy_user`, and
`elk_kibana_integrations_proxy_password`. When the boolean is false (the
default), Kibana connects to the public Elastic Package Registry directly.

```bash
ansible-playbook -i inventory/elk install_elk.yml
```
