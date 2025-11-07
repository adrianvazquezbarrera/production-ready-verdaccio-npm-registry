FROM node:20-alpine

ARG USERNAME=verdaccio
ARG GROUPNAME=verdaccio


ENV VERDACCIO_VERSION=6.2.1
ENV NODE_ENV=production

# Create verdaccio user and directories
RUN addgroup -S ${GROUPNAME} && adduser -S -G ${GROUPNAME} ${USERNAME} \
    && mkdir -p /verdaccio/storage /verdaccio/conf /verdaccio/plugins \
    && chown -R ${USERNAME}:${GROUPNAME} /verdaccio

USER ${USERNAME}
WORKDIR /verdaccio

# Install Verdaccio and htpasswd plugin
RUN npm install --no-audit --no-fund --omit=dev verdaccio@${VERDACCIO_VERSION}

# Copy config and entrypoint
COPY --chown=verdaccio:verdaccio verdaccio/verdaccio-conf/config.yaml /verdaccio/conf/config.yaml
COPY --chown=verdaccio:verdaccio entrypoint.sh /verdaccio/entrypoint.sh
RUN chmod +x /verdaccio/entrypoint.sh

EXPOSE 4873

CMD ["/verdaccio/entrypoint.sh"]