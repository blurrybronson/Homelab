#! /bin/sh

# this script is used to generate the secrets used for this project 
# the secret values will need to manually pasted in from my vault instance for the time being, but this script will create them with the appropriate names 
# can eventually be rewritten to pull using the vault api once it's configured 

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


