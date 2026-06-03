#!/bin/sh

echo "Entrypoint script executing" > /tmp/entrypoint_test
export KC_DB_USERNAME=$(cat /run/secrets/keycloak_db_un)
export KC_DB_PASSWORD=$(cat /run/secrets/keycloak_db_pwd)
export KC_BOOTSTRAP_ADMIN_USERNAME=$(cat /run/secrets/keycloak_admin_un)
export KC_BOOTSTRAP_ADMIN_PASSWORD=$(cat /run/secrets/keycloak_admin_pwd)
exec /opt/keycloak/bin/kc.sh "$@"
