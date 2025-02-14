#!/bin/bash

# Exit on any error
set -e

echo "Starting OpenVPN installation..."

# Update system
yum update -y
yum install -y epel-release
yum install -y openvpn easy-rsa

# Create directories
mkdir -p /etc/openvpn/server
mkdir -p /etc/openvpn/easy-rsa
cp -r /usr/share/easy-rsa/3/* /etc/openvpn/easy-rsa/

# Create vars file
cat > /etc/openvpn/easy-rsa/vars << EOF
set_var EASYRSA_REQ_COUNTRY    "CN"
set_var EASYRSA_REQ_PROVINCE   "Shanghai"
set_var EASYRSA_REQ_CITY       "Shanghai"
set_var EASYRSA_REQ_ORG        "MyOrganization"
set_var EASYRSA_REQ_EMAIL      "admin@example.com"
set_var EASYRSA_REQ_OU         "Community"
set_var EASYRSA_ALGO           "ec"
set_var EASYRSA_DIGEST         "sha512"
EOF

# Initialize PKI and create certificates
cd /etc/openvpn/easy-rsa
./easyrsa init-pki
echo "yes" | ./easyrsa build-ca nopass
echo "yes" | ./easyrsa gen-req server nopass
echo "yes" | ./easyrsa sign-req server server
./easyrsa gen-dh

# Generate HMAC key
cd /etc/openvpn/server
openvpn --genkey --secret ta.key

# Create server configuration
cat > /etc/openvpn/server/server.conf << EOF
port 1194
proto udp
dev tun
ca /etc/openvpn/server/ca.crt
cert /etc/openvpn/server/server.crt
key /etc/openvpn/server/server.key
dh /etc/openvpn/server/dh.pem
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 223.5.5.5"     # AliDNS Primary
push "dhcp-option DNS 223.6.6.6"     # AliDNS Secondary
keepalive 10 120
cipher AES-256-CBC
auth SHA256
tls-auth /etc/openvpn/server/ta.key 0
user nobody
group nobody
persist-key
persist-tun
status openvpn-status.log
verb 3
EOF

# Copy required files
cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/server/
cp /etc/openvpn/easy-rsa/pki/issued/server.crt /etc/openvpn/server/
cp /etc/openvpn/easy-rsa/pki/private/server.key /etc/openvpn/server/
cp /etc/openvpn/easy-rsa/pki/dh.pem /etc/openvpn/server/

# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
sysctl -p

# Configure firewall
firewall-cmd --permanent --add-service=openvpn
firewall-cmd --permanent --add-masquerade
firewall-cmd --permanent --add-port=1194/udp
firewall-cmd --reload

# Start and enable OpenVPN service
systemctl start openvpn-server@server
systemctl enable openvpn-server@server

# Generate client certificate
echo "yes" | ./easyrsa gen-req client1 nopass
echo "yes" | ./easyrsa sign-req client client1

echo "OpenVPN server installation completed!"
echo "Don't forget to:"
echo "1. Open port 1194/UDP in your Alibaba Cloud security group"
echo "2. Generate client configuration files"