## OpenVPN server installation

Script files:  
install_openvpn_server.sh  
create_client_config.sh  

For create_client_config.sh  
Change the SERVER_IP="x.x.x.x" into the server's IP address

Upload both to your server (you can use WinSCP or paste it into a new file)

Make it executable:
```
chmod +x install_openvpn_server.sh
```

Run it as root:
```
./install_openvpn_server.sh
```


This script must be run as root  
It assumes a fresh installation  
It sets up basic security settings  
The script automatically answers "yes" to certificate generation prompts  
You'll still need to configure your Alibaba Cloud security group manually  
--Open port 1194/UDP in your Alibaba Cloud security group  

After running this, you'll need to generate client configuration files  


## generate OpenVPN client configuration files
Save the script on your server

Make it executable:
```
chmod +x create_client_config.sh
```

Run it with a client name (replace "client1" with desired name):
```
sudo ./create_client_config.sh client1
```
