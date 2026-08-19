#! /bin/sh

# defining firewall forwarding rules 
# since podman runs rootless, I cannot have it listen on ports 80 and 443 without compromising on security 
# I will be redirecting ports as follows. 80:8080, 443:8443
default_zone=$(firewall-cmd --get-default-zone)
firewall-cmd --zone=$default_zone --permanent --add-port=80/tcp
firewall-cmd --zone=$default_zone --permanent --add-port=443/tcp
firewall-cmd --zone=$default_zone --permanent --add-forward-port=port=80:proto=tcp:toport=8080
firewall-cmd --zone=$default_zone --permanent --add-forward-port=port=443:proto=tcp:toport=8443
firewall-cmd --reload

# virtual network creation
# creating internal immich network if it doesn't already exist
if ! podman network exists immich_internal; then
	podman network create --subnet 10.89.0.0/24 --gateway 10.89.0.1 immich_internal
fi

# creating the hashicorp vault internal network if it doesn't already exist
if ! podman network exists vault_internal; then
	podman network create --subnet 10.89.8.0/24 --gateway 10.89.8.1 vault_internal
fi

# creating the vaultwarden internal network if it doesn't already exist
if ! podman network exists warden_internal; then
	podman network create --subnet 10.89.9.0/24 --gateway 10.89.9.1 warden_internal
fi

# creating keycloak internal network if it doesn't already exist
if ! podman network exists keycloak_internal; then
	podman network create --subnet 10.89.10.0/24 --gateway 10.89.10.1 keycloak_internal
fi
