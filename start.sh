#!/bin/bash

set -eu

# Create runtime directories
mkdir -p /run/librechat/public
mkdir -p /run/librechat/logs
mkdir -p /run/meili_data

# Create data directories if they don't exist
mkdir -p /app/data/images
mkdir -p /app/data/logs

# If first run, generate secrets
if [[ ! -f /app/data/.env ]]; then
    echo "Generating secrets for first run..."

    # Generate JWT secrets
    JWT_SECRET=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c50)
    JWT_REFRESH_SECRET=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c50)

    # Generate encryption keys for credentials
    CREDS_KEY=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c64)
    CREDS_IV=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c32)

    cat > /app/data/.env <<EOL
export JWT_SECRET=${JWT_SECRET}
export JWT_REFRESH_SECRET=${JWT_REFRESH_SECRET}
export CREDS_KEY=${CREDS_KEY}
export CREDS_IV=${CREDS_IV}
EOL
fi

source /app/data/.env

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
export MEILI_HOST="http://localhost:7700"
export MEILI_MASTER_KEY="${JWT_SECRET}"
export MEILI_NO_ANALYTICS=true

# File paths
export IMAGES_PATH="/app/data/images"
export LOGS_PATH="/run/librechat/logs"

# Change ownership of runtime directories
chown -R cloudron:cloudron /run/librechat
chown -R cloudron:cloudron /run/meili_data
chown -R cloudron:cloudron /app/data

echo "==> Starting LibreChat"
exec /usr/bin/supervisord --configuration /etc/supervisor/supervisord.conf --nodaemon -i LibreChat
