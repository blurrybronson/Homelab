# Files used by Docker/Podman to build the application 
- compose.yaml
- tls/*
- entrypoint.sh

# Files not used to build the container(s) 
- create_secrets.sh
    - this file is only used to create the docker secrets in the event that I move this to a new host 

# Files/direcotires in gitignore 
- tls/ 
