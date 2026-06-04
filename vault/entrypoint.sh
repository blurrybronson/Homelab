#! /bin/sh

# setting environment variables for the auto-unseal 
export AWS_ACCESS_KEY_ID=$(cat /run/secrets/AWS_ACCESS_KEY_ID)
export AWS_SECRET_ACCESS_KEY=$(cat /run/secrets/AWS_ACCESS_KEY)

# starting the vault server 
exec vault server -config=/vault/config/vault.hcl
