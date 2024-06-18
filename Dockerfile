ARG KONG_VERSION=3.4

FROM kong/kong-gateway:${KONG_VERSION}

USER root

# Copy the plugin
COPY --chown=1000:1000 kong/plugins/inflate-gzip /usr/local/share/lua/5.1/kong/plugins/inflate-gzip
# Forcefully activate it by default
RUN sed '20 a "inflate-gzip",' /usr/local/share/lua/5.1/kong/constants.lua > /usr/local/share/lua/5.1/kong/constants.lua.patch && \
    mv /usr/local/share/lua/5.1/kong/constants.lua.patch /usr/local/share/lua/5.1/kong/constants.lua

USER kong
