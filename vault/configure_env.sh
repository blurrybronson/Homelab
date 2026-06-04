#! /bin/sh

# this script is used to generate the secrets used for this project
# the secret values will need to manually pasted in from my vault instance for the time being, but this script will create them with the appropriate names
# can eventually be rewritten to pull using the vault api once it's configured

# gathering user input to create the secrets
read -p "Enter the access key ID: " AWS_ACCESS_KEY_ID
read -s "Enter the access key: " AWS_ACCESS_KEY

# creating the secrets
echo $AWS_ACCESS_KEY_ID | podman secret create --replace AWS_ACCESS_KEY_ID -
echo $AWS_ACCESS_KEY | podman secret create --replace AWS_ACCESS_KEY -

# changing security context and tagging files/directories 
chcon -Rt container_file_t ./tls/
chcon -Rt container_file_t ./config/
chcon -t container_file_t ./entrypoint.sh
