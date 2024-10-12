#!/bin/bash

set -e

# Get OS details
. /etc/os-release
OS_ID=${ID}
OS_VERSION=${VERSION_ID}

# Update package list and install docker.io and wget
sudo apt update
sudo apt install -y docker.io wget

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Create Docker network
sudo docker network create zabbix-network || true

# Create necessary directories
sudo mkdir -p /postgres
sudo mkdir -p /etc/ssl/nginx

sudo docker rm -f postgres-server zabbix-server-pgsql zabbix-web-nginx-pgsql


# Run Postgres container
sudo docker run -d \
  --name postgres-server \
  --network zabbix-network \
  -e POSTGRES_USER="zabbix" \
  -e POSTGRES_PASSWORD="zabbix2" \
  -e POSTGRES_DB="zabbix" \
  -p 6432:5432 \
  -v /postgres:/var/lib/postgresql/data \
  --restart unless-stopped \
  postgres:16.2

# Wait for Postgres to be ready
echo "Waiting for Postgres to start..."
sleep 10

# Run Zabbix backend container
sudo docker run -d \
  --name zabbix-server-pgsql \
  --network zabbix-network \
  -e DB_SERVER_HOST="postgres-server" \
  -e POSTGRES_USER="zabbix" \
  -e POSTGRES_PASSWORD="zabbix2" \
  -e POSTGRES_DB="zabbix" \
  -e ZBX_ENABLE_SNMP_TRAPS="true" \
  -p 10051:10051 \
  --restart unless-stopped \
  zabbix/zabbix-server-pgsql:ubuntu-7.0-latest

# Run Zabbix frontend container
sudo docker run -d \
  --name zabbix-web-nginx-pgsql \
  --network zabbix-network \
  -e ZBX_SERVER_HOST="zabbix-server-pgsql" \
  -e DB_SERVER_HOST="postgres-server" \
  -e POSTGRES_USER="zabbix" \
  -e POSTGRES_PASSWORD="zabbix2" \
  -e POSTGRES_DB="zabbix" \
  -p 8080:8080 \
  -v /etc/ssl/nginx:/etc/ssl/nginx:ro \
  --restart unless-stopped \
  zabbix/zabbix-web-nginx-pgsql:ubuntu-7.0-latest

# Install Zabbix agent 2
if [ "$OS_ID" = "ubuntu" ]; then
    ZABBIX_PKG="zabbix-release_7.0-1+ubuntu${OS_VERSION}_all.deb"
    ZABBIX_URL="https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/${ZABBIX_PKG}"
elif [ "$OS_ID" = "debian" ]; then
    # Remove decimal point for Debian version if necessary
    OS_VERSION="${OS_VERSION%%.*}"
    ZABBIX_PKG="zabbix-release_7.0-1+debian${OS_VERSION}_all.deb"
    ZABBIX_URL="https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/${ZABBIX_PKG}"
else
    echo "Unsupported OS: $OS_ID"
    exit 1
fi

# Download and install Zabbix repository
wget $ZABBIX_URL
sudo dpkg -i $ZABBIX_PKG
sudo apt update

# Install zabbix-agent2
sudo apt install -y zabbix-agent2

# Configure zabbix-agent2
sudo sed -i 's/^Server=.*/Server=127.0.0.1/' /etc/zabbix/zabbix_agent2.conf
sudo sed -i 's/^ServerActive=.*/ServerActive=127.0.0.1/' /etc/zabbix/zabbix_agent2.conf

# Start and enable zabbix-agent2
sudo systemctl enable zabbix-agent2
sudo systemctl restart zabbix-agent2

echo "Installation completed successfully."

