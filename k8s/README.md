# K8s Cluster Playbooks

These playbooks build a small Kubernetes cluster for learning.

## Full Rebuild

Run from the repository root.

```bash
ansible-playbook -i inventory/k8s_k112 -i inventory/kvm_server k8s/00_remove_k8s_cluster_mahines.yaml
ansible-playbook -i inventory/k8s_k112 -i inventory/kvm_server k8s/01_create_k8s_cluster_machines.yaml
ansible-playbook -i inventory/k8s_k112 k8s/02_full_rollout.yaml
ansible-playbook -i inventory/k8s_k112 k8s/03_create_etcd_cluster.yaml
ansible-playbook -i inventory/k8s_k112 k8s/04_setup_k8s_master.yaml
ansible-playbook -i inventory/k8s_k112 k8s/05_add_k8s_master.yaml -e host=master2
ansible-playbook -i inventory/k8s_k112 k8s/06_add_k8s_worker.yaml -e host=worker1
ansible-playbook -i inventory/k8s_k112 k8s/06_add_k8s_worker.yaml -e host=worker2
ansible-playbook -i inventory/k8s_k112 k8s/06_add_k8s_worker.yaml -e host=worker3
ansible-playbook -i inventory/k8s_k112 k8s/08_deploy_test_nginx.yaml
```

## Notes

- `04_setup_k8s_master.yaml` installs Calico CNI after initializing `master1`.
- `02_full_rollout.yaml` runs root `full.yml` on the `k8s` inventory group.
- Additional masters and workers do not need a separate CNI playbook. Calico starts on new nodes automatically.
- `squid_ip` is optional, but useful when cluster nodes cannot reach package or image registries directly.
- `05_add_k8s_master.yaml` defaults to `host=master2`.
- `06_add_k8s_worker.yaml` defaults to `host=worker1`.
- `08_deploy_test_nginx.yaml` creates a test `nginx` Deployment and NodePort Service in namespace `test-nginx`.

## Check Cluster

On `master1`:

```bash
sudo kubectl --kubeconfig /etc/kubernetes/admin.conf get nodes
sudo kubectl --kubeconfig /etc/kubernetes/admin.conf get pods -A
sudo kubectl --kubeconfig /etc/kubernetes/admin.conf -n test-nginx get pods -o wide
sudo kubectl --kubeconfig /etc/kubernetes/admin.conf -n test-nginx get svc
```

Test nginx through NodePort:

```bash
curl http://10.9.1.31:30080
```
