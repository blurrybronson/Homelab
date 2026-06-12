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

# creating podman backend network for container to communicate across securely 
# network only created if it doesn't already exist  
if ! podman network exists backend; then
	podman network create backend
fi 
