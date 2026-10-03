# Auditbeat role

Installs Auditbeat and sends events to Logstash on `10.9.0.90:5044` by default.
Override the destination with `elk_host`:

```bash
ansible-playbook -i inventory/my_hosts 01_bare_host.yml \
  -e target_hosts=my_hosts -e elk_host=10.9.0.90
```

The Elastic apt repository and Auditbeat management are enabled by default. To
skip them for a host, set this in its host variables:

```yaml
auditbeat_elastic_apt_repo_enabled: false
```
