# ansible

This is my awesome ansible repository!

Central Debian/Ubuntu VDS and MikroTik CEF logging: [deployment and verification](docs/logging.md).

Internal tunnel/LAN routing: [policy, repair and verification](docs/internal-networks.md).

Trusted networks and SSH protection: [deployment and verification](docs/trusted-access.md).

Public RouterOS exposure: [vds7_CHR and K16_112 audit](docs/edge-exposure.md).

# add new key on main machine (if not exist):
ssh-keygen -t ed25519 -C "ansible"
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/alexander/.ssh/id_ed25519): /home/alexander/.ssh/priv/ansible
Enter passphrase (empty for no passphrase): [empty]
Enter same passphrase again: [empty]

# use separate username for ansible on all hosts
server1$ sudo useradd -s /bin/bash -m -G sudo ansible
server1$ sudo passwd ansible
server2$ sudo useradd -s /bin/bash -m -G sudo ansible
server2$ sudo passwd ansible
server3$ sudo useradd -s /bin/bash -m -G sudo ansible
server3$ sudo passwd ansible

# copy key to all hosts from main host
ssh-copy-id -i ~/.ssh/priv/ansible.pub ansible@10.9.0.156
ssh-copy-id -i ~/.ssh/priv/ansible.pub ansible@10.9.0.157
ssh-copy-id -i ~/.ssh/priv/ansible.pub ansible@10.9.0.160

# check availibility
ansible all -i inventory -m ping

# run single command 
ansible all -i inventory -a "sudo iptables -S"

# run playbook with vault password from file
ansible-playbook -i inventory/v install_gitlab.yaml --vault-password-file ~/.ansible/vault_pass.txt

# run playbook with vault password prompt
ansible-playbook -i inventory/v install_gitlab.yaml --ask-vault-pass

# zabbix-proxy
sudo docker run --name zabbix-proxy-sqlite3 -e ZBX_HOSTNAME=RuVDS -e ZBX_SERVER_HOST=45.35.14.80 -e ZBX_CONFIGFREQUENCY=30 -d --restart unless-stopped zabbix/zabbix-proxy-sqlite3:alpine-5.4.11
sudo docker logs zabbix-proxy-sqlite3

# nginx
sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt

sudo cat /etc/nginx/conf.d/my_server.conf
server {
    listen              443 ssl;
    server_name         _;
    ssl_certificate     /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
	proxy_pass http://localhost:80/;
    }

    location /test {
	proxy_pass http://localhost:80/;
    }
}

# zabbix 6.0
sudo wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-1+debian10_all.deb
sudo dpkg -i zabbix-release_6.0-1+debian10_all.deb
sudo apt update
sudo at install nginx
sudo apt install zabbix-server-pgsql zabbix-frontend-php php7.3-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql
sudo systemctl enable --now postgresql
sudo -u postgres createuser --pwprompt zabbix
[passwd for zabbix user]
sudo -u postgres createdb -O zabbix zabbix
zcat /usr/share/doc/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix
sudo vim /etc/nginx/conf.d/zabbix.conf
    listen 80;
    server_name 10.9.0.157;
sudo vim /etc/zabbix/zabbix_server.conf
    BDPasswd=xxxxxxxx
sudo systemctl restart zabbix-server zabbix-agent nginx php7.3-fpm
sudo systemctl enable zabbix-server zabbix-agent nginx php7.3-fpm

# grafana
sudo apt-get install -y gnupg2 curl software-properties-common
curl https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
sudo apt update
sudo apt install grafana
sudo systemctl enable --now grafana-server
sudo systemctl start grafana-server
[http://my-ip-address:3000]


domain reg.ru 89 рублей в год
#172.107.174.18 vds4.space
69.30.237.130 vds4.space


nginx
root@d59bfaccc9fc:/# cat /etc/nginx/conf.d/proxy.conf 
upstream  test {
    server vds4.space;
}

server {
    listen              443 ssl;
    #listen		80;
    server_name         vds4.space;
    ssl_certificate /etc/letsencrypt/live/vds4.space/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/vds4.space/privkey.pem; # managed by Certbot
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    #return 308 https://$host$request_uri;


    location /owncloud {
        proxy_pass http://172.17.0.2:1953;
        proxy_http_version 1.1;

#        proxy_set_header    Accept-Encoding     "";
#        proxy_set_header    Host                172.107.174.18;
#        proxy_set_header    X-Real-IP           $remote_addr;
#        proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
#        proxy_set_header    X-Forwarded-Proto   http;
#        proxy_set_header    Authorization       "";

    }

    location /admin {
        proxy_pass http://172.107.174.18:5280/admin;
        proxy_http_version 1.1;
	
	proxy_set_header    Accept-Encoding     "";
        proxy_set_header    Host                172.107.174.18/admin;
        proxy_set_header    X-Real-IP           $remote_addr;
        proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto   http;
        proxy_set_header    Authorization       "";
    }
    location / {
        proxy_pass http://vds4.space:2080;
        proxy_http_version 1.1;
	
	access_log /var/log/nginx/rocket.chat.access.log;
	error_log /var/log/nginx/rocket.chat.error.log;

            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;
            proxy_set_header X-Nginx-Proxy true;
    }

}


apt install certbot python3-certbot-nginx
certbot --nginx -d


# rocket.chat
sudo  docker run --name db -d mongo:4.4 --replSet rs0 --oplogSize 128
docker exec -ti db mongo --eval "printjson(rs.initiate())"
sudo docker run --name rocketchat -p 2080:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/local -d rocket.chat

# owncloud
sudo docker run --name owncloud -d -e OWNCLOUD_DOMAIN=localhost:8080 -p1953:8080 -v /owncloud:/mnt/data owncloud/server

# SOCKS5 proxy
sudo docker run -d --name socks5 -p 1980:1080 -e PROXY_USER=proxy -e PROXY_PASSWORD=proxy_K174gl1a serjs/go-socks5-proxy

# nginx proxy
sudo docker run -d -v /etc/my_proxy/:/etc/nginx/conf.d/ --name proxy -p 80:80 -p 443:443 nginx

# ejabberd
sudo docker run --name ejabberd -d -p 5222:5222 -p 5969:5269 -p 5280:5280 ejabberd/ecs


# todo:
zabbix-agent hostname
apt install fio
conatiners owncloud

ansible-galaxy collection install community.docker

sudo apt -y install software-properties-common
sudo apt-add-repository ppa:ansible/ansible


# Reg.ru
Купить любой домен 2го уровня за 200р. на год (напр., vds2.space)
Зайти в ЛК -> Главная -> Домены -> Настройка домена -> DNS-серверы и управление зоной -> Добавить A-запись * тем же IP-адресом
Выждать около получаса и проверить резлв любого поддемена (напр., abc.vds2.space)

### mikroitik zabbix proxy 7.2
У микротика есть известная проблема с пуллом образа из реджистри, поэтому пуллить пришлось отдельно на армовую машину, сохранять и импортировать в микротике из файла

on arm64 machine:
sudo docker pull zabbix/zabbix-proxy-sqlite3:alpine-7.2.1
sudo docker save zabbix/zabbix-proxy-sqlite3:alpine-7.2.1 -o zabbix-proxy-7.2.1-alpine.tar
sudo chown apopov: zabbix-proxy-7.2.1-alpine.tar
scp staging-virginia-controller-1:/home/apopov/zabbix-proxy-7.2.1-alpine.tar .

on local machine:
scp zabbix-proxy-7.2.1-alpine.tar admin@10.9.0.1:/usb2/

on mikrotik
container -> new -> file: /usb2/zabbix-proxy-7.2.1-alpine.tar

/container add envlist=zabbixproxy_envs hostname=mikrotik_k16_k112 interface=ZABBIX_PROXY logging=yes root-dir=usb1-part1/zabbixproxy start-on-boot=yes

wait 2 minutes until files in /usb2/zabbix-proxy/* will be created




---
| Сеть | Назначение | Фактическое использование |
|---|---|---|
| `10.250.0.0/24` | SSTP | vds7 и четыре MikroTik |
| `10.250.1.0/24` | обычный WireGuard | vds1/vds8 ↔ 3Ekipazhnyi64/k16_21 |
| `10.250.2.0/24` | AmneziaWG mesh VDS | vds1, vds2, vds5, vds6, vds8 |
| `10.250.3.0/24` | L2TP | K16_112 ↔ три MikroTik |
| `10.250.4.0/24` | GRE | четыре соединения с vds6 |
| `10.250.5.0/24` | резервная service-сеть | активных адресов сейчас нет |
| `10.250.6.0/24` | транспорт WG/AWG | VDS ↔ vds7, K16/Misha ↔ vds1/vds8 |
| `10.255.0.0/24` | OSPF loopback | по одному `/32` на каждом маршрутизаторе/VDS |

| Хост | Loopback | SSTP | WireGuard/AWG | L2TP | GRE |
|---|---|---|---|---|---|
| vds1 | `10.255.0.1/32` | — | `10.250.1.1`, `10.250.2.1`, `10.250.6.1` | — | — |
| vds2 | `10.255.0.2/32` | — | `10.250.2.2`, `10.250.6.2` | — | — |
| vds5 | `10.255.0.5/32` | — | `10.250.2.5`, `10.250.6.5` | — | — |
| vds6 | `10.255.0.6/32` | — | `10.250.2.6`, `10.250.6.6` | — | `.2`, `.6`, `.14`, `.18` в `10.250.4.0/24` |
| vds8 | `10.255.0.8/32` | — | `10.250.1.8`, `10.250.2.8`, `10.250.6.8` | — | — |
| vds7_CHR | `10.255.0.7/32` | `10.250.0.7/32` | `10.250.6.7/32` | — | — |
| K16_112 | `10.255.0.112/32` | `10.250.0.112/32` | `10.250.6.112/32` | `10.250.3.112/32` | `10.250.4.1/30` |
| 3Ekipazhnyi64 | `10.255.0.64/32` | `10.250.0.64/32` | `10.250.1.64/24` | `10.250.3.64/32` | `10.250.4.5/30` |
| k16_21 | `10.255.0.21/32` | `10.250.0.21/32` | `10.250.1.21/24` | `10.250.3.21/32` | `10.250.4.13/30` |
| Misha | `10.255.0.24/32` | `10.250.0.24/32` | `10.250.6.24/32` | `10.250.3.24/32` | `10.250.4.17/30` |

Для point-to-point интерфейсов адрес может повторяться:
- vds7 использует 10.250.6.7/32 на пяти отдельных WG-интерфейсах.
- vds1 использует 10.250.6.1 на wg2, wg3, wg4.
- vds8 использует 10.250.6.8 на wg2, wg3, wg4.
- K16 и Misha используют один локальный адрес на отдельных соединениях с vds1 и vds8.
Это допустимо, поскольку интерфейсы point-to-point имеют разные peer/network endpoints.