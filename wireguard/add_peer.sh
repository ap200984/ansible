#!/bin/bash

WG_CONF="/etc/wireguard/wg0.conf"
WG_INTERFACE="wg0"
NETWORK_PREFIX="10.250.0."
DNS_SERVERS="1.1.1.1,1.0.0.1"
WG_PORT="56685"
WG_ENDPOINT=$(hostname -I | awk '{print $1}') # Server's public IP

# Install qrencode if not installed
if ! command -v qrencode &> /dev/null; then
    echo "qrencode not found, installing..."
    sudo apt-get update
    sudo apt-get install -y qrencode
fi

# Ask for the name of the new peer
read -p "Enter the name of the new peer: " PEER_NAME

# Generate private and public keys for the new peer
PEER_PRIVATE_KEY=$(wg genkey)
PEER_PUBLIC_KEY=$(echo $PEER_PRIVATE_KEY | wg pubkey)
PEER_PRESHARED_KEY=$(wg genpsk)

# Find the next available IP address in the network
LAST_OCTET=$(grep -oP '10\.250\.0\.\K\d+' $WG_CONF | sort -n | tail -n 1)
NEW_IP="${NETWORK_PREFIX}$((LAST_OCTET + 1))"

# Add the new peer to the WireGuard config
sudo tee -a $WG_CONF > /dev/null <<EOL

[Peer]
PublicKey = $PEER_PUBLIC_KEY
PresharedKey = $PEER_PRESHARED_KEY
AllowedIPs = ${NEW_IP}/32
EOL

# Create the peer's configuration file
PEER_CONF="${PEER_NAME}.conf"
sudo tee $PEER_CONF > /dev/null <<EOL
[Interface]
PrivateKey = $PEER_PRIVATE_KEY
Address = ${NEW_IP}/32
DNS = $DNS_SERVERS

[Peer]
PublicKey = $(wg show $WG_INTERFACE public-key)
PresharedKey = $PEER_PRESHARED_KEY
Endpoint = $WG_ENDPOINT:$WG_PORT
AllowedIPs = 0.0.0.0/0
EOL

# Print the QR code of the new peer's configuration
qrencode -t ansiutf8 < $PEER_CONF

echo "New peer configuration file saved as $PEER_CONF."

# Restart WireGuard to apply the changes
echo "Restarting WireGuard..."
sudo systemctl restart wg-quick@$WG_INTERFACE

echo "WireGuard has been restarted. The new peer is now active."
