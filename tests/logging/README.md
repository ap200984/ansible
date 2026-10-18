# Logstash parser fixtures

Run from the repository root with the same inventory and SSH options as the logging deployment:

```sh
ansible-playbook -i inventory tests/logging/fixtures.yml
```

The playbook renders the production pipeline, replaces only its Elasticsearch output with a temporary JSON file, and starts a separate memory-limited Logstash container using the installed image. No ports are published and the container has no network access outside its loopback interface. Generated Linux JSON and RouterOS CEF messages travel through the real TCP inputs. Assertions cover framing, parsing, timestamp timezones, ECS field types and index routing. The container and temporary files are removed on success or failure.

The RouterOS BSD fixture follows MikroTik's [documented CEF message example](https://manual.mikrotik.com/docs/diagnostics-monitoring-and-troubleshooting/log/#message-formats).
