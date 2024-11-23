FROM cloudron/base:4.2.0@sha256:46da2fffb36353ef714f97ae8e962bd2c212ca091108d768ba473078319a47f4

# Install MeiliSearch
RUN curl -L https://install.meilisearch.com | sh && \
    mv meilisearch /usr/local/bin/ && \
    chmod +x /usr/local/bin/meilisearch

WORKDIR /app/code

# Create directories
RUN mkdir -p /app/data/.npm && \
    mkdir -p /app/data/.config/npm && \
    mkdir -p /run/meili_data && \
    mkdir -p /run/librechat/public && \
    mkdir -p /run/librechat/logs && \
    chown -R cloudron:cloudron /app/data/.npm /app/data/.config /run/meili_data /run/librechat

# Set npm config
ENV NPM_CONFIG_CACHE=/app/data/.npm
ENV NPM_CONFIG_USERCONFIG=/app/data/.config/npm/npmrc

# Install LibreChat
ARG LIBRECHAT_VERSION=v0.7.5
RUN curl -L "https://github.com/danny-avila/LibreChat/archive/${LIBRECHAT_VERSION}.tar.gz" | tar -xz --strip-components 1 -C /app/code

# Install dependencies and build as cloudron user
RUN chown -R cloudron:cloudron /app/code && \
    gosu cloudron:cloudron sh -c '\
    npm config set cache /app/data/.npm && \
    npm config set userconfig /app/data/.config/npm/npmrc && \
    npm config set fetch-retry-maxtimeout 600000 && \
    npm config set fetch-retries 5 && \
    npm config set fetch-retry-mintimeout 15000 && \
    npm install --no-audit && \
    export NODE_OPTIONS="--max-old-space-size=2048" && \
    npm run frontend && \
    npm prune --production && \
    npm cache clean --force'

# Setup runtime directories
RUN rm -rf /app/code/client/dist/public && \
    ln -s /run/librechat/public /app/code/client/dist/public && \
    ln -s /run/librechat/logs /app/code/api/logs && \
    chown -R cloudron:cloudron /app/code /app/data /run/librechat /run/meili_data

# Add supervisor configs
ADD supervisor/* /etc/supervisor/conf.d/
RUN sed -e 's,^logfile=.*$,logfile=/run/supervisord.log,' -i /etc/supervisor/supervisord.conf

COPY start.sh /app/pkg/
RUN chmod +x /app/pkg/start.sh

CMD ["/app/pkg/start.sh"]
