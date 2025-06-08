# Dockerfile
FROM cloudron/base:4.2.0@sha256:46da2fffb36353ef714f97ae8e962bd2c212ca091108d768ba473078319a47f4

# Install MeiliSearch
RUN curl -L https://install.meilisearch.com | sh && \
    mv meilisearch /usr/local/bin/ && \
    chmod +x /usr/local/bin/meilisearch

WORKDIR /app/code

# Create npm cache directories in /run (temporary)
RUN mkdir -p /run/npm-cache && \
    mkdir -p /run/npm-config && \
    mkdir -p /run/meili_data && \
    mkdir -p /run/temp && \
    chown -R cloudron:cloudron /run/npm-cache /run/npm-config /run/meili_data /run/temp

# Set npm config to use temporary directories
ENV NPM_CONFIG_CACHE=/run/npm-cache
ENV NPM_CONFIG_USERCONFIG=/run/npm-config/npmrc

# Install LibreChat
ARG LIBRECHAT_VERSION=v0.7.8
RUN curl -L "https://github.com/danny-avila/LibreChat/archive/${LIBRECHAT_VERSION}.tar.gz" | tar -xz --strip-components 1 -C /app/code


# Install dependencies and build as cloudron user
RUN chown -R cloudron:cloudron /app/code && \
    gosu cloudron:cloudron sh -c '\
    npm config set cache /run/npm-cache && \
    npm config set userconfig /run/npm-config/npmrc && \
    npm config set fetch-retry-maxtimeout 600000 && \
    npm config set fetch-retries 5 && \
    npm config set fetch-retry-mintimeout 15000 && \
    npm install --no-audit && \
    export NODE_OPTIONS="--max-old-space-size=2048" && \
    npm run frontend && \
    npm prune --production && \
    npm cache clean --force'

# Setup symlinks for persistent and temporary data
RUN rm -rf /app/code/client/public && \
    rm -rf /app/code/api/logs && \
    rm -rf /app/code/uploads && \
    rm -rf /app/code/data && \
    ln -s /app/data/public /app/code/client/public && \
    ln -s /app/data/logs /app/code/api/logs && \
    ln -s /app/data/data /app/code/data && \
    ln -s /app/data/uploads /app/code/uploads && \
    ln -s /app/data/librechat.yaml /app/code/librechat.yaml && \
    chown -R cloudron:cloudron /app/code

# Add supervisor configs
ADD supervisor/* /etc/supervisor/conf.d/
RUN sed -e 's,^logfile=.*$,logfile=/run/supervisord.log,' -i /etc/supervisor/supervisord.conf

COPY default.env /app/code/.env
COPY start.sh /app/pkg/
RUN chmod +x /app/pkg/start.sh

CMD ["/app/pkg/start.sh"]
