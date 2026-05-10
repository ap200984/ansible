### ПОдключение к удаленному кластеру через SSH-прокси
1. Добавляем IP на localhost
   sudo ip addr add 10.9.1.5/32 dev lo
2. Подниамем тоннель
   ssh -fN -L 10.9.1.5:8443:10.9.1.5:6443 user@master1
3. cat ./.ssh/config 
Host jump-host
    HostName 86.110.170.70
    Port 19020
    User user
    IdentityFile ~/.ssh/priv/user
    UserKnownHostsFile /dev/null
    StrictHostKeyChecking no

Host 10.9.*
    User user
    IdentityFile ~/.ssh/internal_key
    ProxyJump jump-host
    UserKnownHostsFile /dev/null
    StrictHostKeyChecking no

Host etcd1 etcd2 etcd3 master1 master2 work1 worker2 worker3 lb1
    User user
    IdentityFile ~/.ssh/internal_key
    ProxyJump jump-host
    UserKnownHostsFile /dev/null
    StrictHostKeyChecking no

4. user@HP:~$ kubectl get nodes
NAME      STATUS   ROLES           AGE   VERSION
master1   Ready    control-plane   21h   v1.30.14
master2   Ready    control-plane   18h   v1.30.14
worker1   Ready    worker          18h   v1.30.14
worker2   Ready    worker          18h   v1.30.14
worker3   Ready    worker          18h   v1.30.14

