#! /bin/sh

# this script is used to configure permissions for the various files and directories used in this project 
# this includes security contexts, podman uuid issues, individual file permissions, etc. 
# this script will also work through secret creation for secrets passed into the containers 

# setting SELinux context for: 
# tls directory (SSL certs) 
# entrypoint script (Keycloak env variables)  
chcon -t container_file_t ./entrypoint.sh
chcon -Rt container_file_t ./tls/ 

# setting permissions for tls directory 
chown -R 1000:1000 ./tls/
chmod 755 ./tls
chmod 644 ./tls/fullchain.pem
chmod 640 ./tls/privkey.pem

# working through secret creation 
# gathering user input to create the secrets 
read -p "Enter the DB username: " db_username 
read -p "Enter the DB password: " db_password
read -p "Enter the keycloak username: " kc_username
read -p "Enter the keycloak password: " kc_password 

# creating the secrets
echo $db_username | podman secret create keycloak_db_un -
echo $db_password | podman secret create keycloak_db_pwd -
echo $kc_username | podman secret create keycloak_admin_un -
echo $kc_password | podman secret create keycloak_admin_pwd -
