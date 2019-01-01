FROM php:7.2-fpm-alpine

ARG BUILD_DATE
ARG VCS_REF

LABEL maintainer="John Lamp" \
  org.label-schema.name="SiteBar" \
  org.label-schema.description="Minimal SiteBar docker image based on Alpine Linux." \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/j3lamp/docker-sitebar" \
  org.label-schema.schema-version="1.0"

ARG UID=1502
ARG GID=1502

RUN set -ex                                                                         \
  && apk update                                                                     \
  && apk upgrade                                                                    \
  && apk add                                                                        \
    alpine-sdk                                                                      \
    autoconf                                                                        \
    bash                                                                            \
    nginx                                                                           \
    postgresql-dev                                                                  \
    postgresql-libs                                                                 \
    supervisor                                                                      \
    tini                                                                            \
    wget                                                                            \
# PHP Extensions
  && docker-php-ext-install mysqli opcache pdo_mysql pdo_pgsql pgsql                \
  && pecl install APCu-5.1.11                                                       \
  && docker-php-ext-enable apcu                                                     \
# Remove dev packages
  && apk del                                                                        \
    alpine-sdk                                                                      \
    autoconf                                                                        \
    postgresql-dev                                                                  \
  && rm -rf /var/cache/apk/*                                                        \
# Add user for sitebar
  && addgroup -g ${GID} sitebar                                                     \
  && adduser -u ${UID} -h /opt/sitebar -H -G sitebar -s /sbin/nologin -D sitebar    \
  && mkdir -p /opt                                                                  \
# Download SiteBar v3.6 plus fixes and adjustments
  && cd /tmp                                                                        \
  && COMMIT_HASH="33c7dd96c3d3e31f6cbbc2769e013d36b18c109a"                         \
  && SITEBAR_ZIP_URL="https://github.com/j3lamp/sitebar/archive/${COMMIT_HASH}.zip" \
  && wget -q "${SITEBAR_ZIP_URL}"                                                   \
# Extract
  && unzip ${COMMIT_HASH}.zip -d /opt                                               \
  && mv /opt/sitebar-${COMMIT_HASH} /opt/sitebar                                    \
  && rm -Rf /opt/sitebar/adm                                                        \
  && mkdir /config                                                                  \
  && ln -s /config /opt/sitebar/adm                                                 \
# Clean up
  && rm -rf /tmp/* /root/.gnupg /var/www/*

COPY root /

RUN chmod +x /usr/local/bin/run.sh

VOLUME ["/config"]

EXPOSE 80

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/run.sh"]
