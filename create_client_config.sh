#!/bin/bash

# Set variables
CLIENT_NAME=$1
SERVER_IP="x.x.x.x"
OUTPUT_DIR="/etc/openvpn/client-configs"
KEY_DIR="/etc/openvpn/easy-rsa/pki"
TA_KEY="/etc/openvpn/server/ta.key"

# Check if client name was provided
if [ -z "$CLIENT_NAME" ]; then
    echo "Usage: $0 <client_name>"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p ${OUTPUT_DIR}

# Generate ta.key if it doesn't exist
if [ ! -f "$TA_KEY" ]; then
    cd /etc/openvpn/server
    openvpn --genkey --secret ta.key
fi

# Create client configuration
cat > ${OUTPUT_DIR}/${CLIENT_NAME}.ovpn << EOF
client
dev tun
proto udp
remote ${SERVER_IP} 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
auth SHA256
verb 3
key-direction 1

<ca>
$(cat ${KEY_DIR}/ca.crt)
</ca>

<cert>
$(cat ${KEY_DIR}/issued/${CLIENT_NAME}.crt)
</cert>

<key>
$(cat ${KEY_DIR}/private/${CLIENT_NAME}.key)
</key>

<tls-auth>
$(cat ${TA_KEY})
</tls-auth>
EOF

echo "Client configuration has been created at: ${OUTPUT_DIR}/${CLIENT_NAME}.ovpn"
echo "Transfer this file to your client device and use it with OpenVPN client"

# Make the configuration file readable
chmod 644 ${OUTPUT_DIR}/${CLIENT_NAME}.ovpn