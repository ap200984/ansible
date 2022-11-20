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

# copy key to all hosts from main host
ssh-copy-id -i ~/.ssh/ansible.pub ansible@10.9.0.156
ssh-copy-id -i ~/.ssh/ansible.pub ansible@10.9.0.157
ssh-copy-id -i ~/.ssh/ansible.pub ansible@10.9.0.160

# check availibility
ansible all -i inventory -m ping

# run single command 
ansible all -i inventory -a "sudo iptables -S"

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
172.107.174.18 vds4.online

nginx
# configuration file /etc/nginx/conf.d/proxy.conf:
upstream  test {
    server vds4.online;
}

server {
    listen              443 ssl;
    #listen		80;
    server_name         172.107.174.18;
    ssl_certificate     /etc/nginx/conf.d/nginx-selfsigned.crt;
    ssl_certificate_key /etc/nginx/conf.d/nginx-selfsigned.key;
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    #return 308 https://$host$request_uri;


    location /owncloud {
        proxy_pass http://172.17.0.2:1953;
        proxy_http_version 1.1;
        #proxy_set_header Connection "";
    }

    location /jabber {
        proxy_pass http://172.107.174.18:5280/admin;
        proxy_http_version 1.1;
    }
    location / {
        proxy_pass http://127.0.0.1;
        proxy_http_version 1.1;
    }
}

apt install certbot python3-certbot-nginx
certbot --nginx -d


