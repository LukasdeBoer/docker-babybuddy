FROM ghcr.io/linuxserver/baseimage-alpine-nginx:3.16

# set version label
ARG BUILD_DATE
ARG VERSION
ARG BABYBUDDY_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

ENV S6_STAGE2_HOOK="/init-hook"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    build-base \
    jpeg-dev \
    libffi-dev \
    libxml2-dev \
    libxslt-dev \
    postgresql-dev \
    python3-dev \
    zlib-dev && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    jpeg \
    libffi \
    libpq \
    libxml2 \
    libxslt \
    py3-mysqlclient \
    py3-pip \
    python3 && \
  echo "**** install babybuddy ****" && \
  if [ -z ${BABYBUDDY_VERSION+x} ]; then \
    BABYBUDDY_VERSION=$(curl -sX GET "https://api.github.com/repos/babybuddy/babybuddy/releases/latest" \
      | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  curl -o \
    /tmp/babybuddy.tar.gz -L \
    "https://github.com/babybuddy/babybuddy/archive/refs/tags/${BABYBUDDY_VERSION}.tar.gz" && \
  mkdir -p /app/www/public && \
  tar xf \
    /tmp/babybuddy.tar.gz -C \
    /app/www/public --strip-components=1 && \
  cd /app/www/public && \
  pip3 install -U --no-cache-dir \
    pip \
    wheel && \
  pip install --no-cache-dir --ignore-installed --find-links https://wheel-index.linuxserver.io/alpine-3.16/ -r requirements.txt && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /tmp/* \
    /root/.cache

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 8000
VOLUME /config
