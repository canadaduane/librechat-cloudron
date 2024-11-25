#!/bin/bash

set -eu

# Email Configuration
export EMAIL_HOST="${CLOUDRON_MAIL_SMTP_SERVER}"
export EMAIL_PORT="${CLOUDRON_MAIL_SMTP_PORT}"
export EMAIL_USERNAME="${CLOUDRON_MAIL_SMTP_USERNAME}"
export EMAIL_PASSWORD="${CLOUDRON_MAIL_SMTP_PASSWORD}"
export EMAIL_FROM="${CLOUDRON_MAIL_FROM}"
export EMAIL_FROM_NAME="LibreChat"
export EMAIL_ENCRYPTION="TLS"

# OpenID Connect Settings
export OPENID_ISSUER="${CLOUDRON_OIDC_ISSUER}/.well-known/openid-configuration"
export OPENID_CLIENT_ID=${CLOUDRON_OIDC_CLIENT_ID}
export OPENID_CLIENT_SECRET=${CLOUDRON_OIDC_CLIENT_SECRET}
export OPENID_SCOPE="openid profile email"
export OPENID_CALLBACK_URL="/oauth/openid/callback"
export OPENID_BUTTON_LABEL="Login with Cloudron"

# Create persistent data directories
mkdir -p /app/data/public
mkdir -p /app/data/logs
mkdir -p /app/data/uploads/temp
mkdir -p /app/data/config
mkdir -p /app/data/data
mkdir -p /app/data/meili_data


# If first run, generate secrets
if [[ ! -f /app/data/secrets.env ]]; then
    echo "Generating secrets for first run..."

    # Generate JWT secrets
    JWT_SECRET=$(hexdump -n 32 -v -e '/1 "%02x"' /dev/urandom)
    JWT_REFRESH_SECRET=$(hexdump -n 32 -v -e '/1 "%02x"' /dev/urandom)

    # Generate encryption keys for credentials
    CREDS_KEY=$(hexdump -n 32 -v -e '/1 "%02x"' /dev/urandom)
    CREDS_IV=$(hexdump -n 16 -v -e '/1 "%02x"' /dev/urandom)

    # Generate MeiliSearch master key
    MEILI_MASTER_KEY=$(hexdump -n 32 -v -e '/1 "%02x"' /dev/urandom)

    cat > /app/data/secrets.env <<EOL
export JWT_SECRET=${JWT_SECRET}
export JWT_REFRESH_SECRET=${JWT_REFRESH_SECRET}
export CREDS_KEY=${CREDS_KEY}
export CREDS_IV=${CREDS_IV}
export MEILI_MASTER_KEY=${MEILI_MASTER_KEY}
EOL
fi
source /app/data/secrets.env

# If first run, generate config
if [[ ! -f /app/data/.env ]]; then cp /app/code/.env /app/data/.env; fi
source /app/data/.env
if [[ ! -f /app/data/librechat.yaml ]]; then touch /app/data/librechat.yaml; fi


# Setup environment variables
export HOST="0.0.0.0"
export PORT="3080"
export APP_TITLE="LibreChat"
export DOMAIN_CLIENT="https://${CLOUDRON_APP_DOMAIN}"
export DOMAIN_SERVER="https://${CLOUDRON_APP_DOMAIN}"

# Database connections
export MONGO_URI="mongodb://${CLOUDRON_MONGODB_USERNAME}:${CLOUDRON_MONGODB_PASSWORD}@${CLOUDRON_MONGODB_HOST}:${CLOUDRON_MONGODB_PORT}/${CLOUDRON_MONGODB_DATABASE}"
export DATABASE_URL="postgresql://${CLOUDRON_POSTGRESQL_USERNAME}:${CLOUDRON_POSTGRESQL_PASSWORD}@${CLOUDRON_POSTGRESQL_HOST}:${CLOUDRON_POSTGRESQL_PORT}/${CLOUDRON_POSTGRESQL_DATABASE}"

# MeiliSearch configuration
export SEARCH=true
export MEILI_HOST="http://localhost:7700"
export MEILI_NO_ANALYTICS=true


# Change ownership of data directories
chown -R cloudron:cloudron /app/data
chown -R cloudron:cloudron /run/temp
chown -R cloudron:cloudron /run/meili_data

echo "==> Starting LibreChat"
exec /usr/bin/supervisord --configuration /etc/supervisor/supervisord.conf --nodaemon -i LibreChat
