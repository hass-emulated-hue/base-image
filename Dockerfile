ARG HASS_ARCH=amd64

FROM python:3.8-slim as wheels-builder

ENV PIP_EXTRA_INDEX_URL=https://www.piwheels.org/simple

# Install buildtime packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        build-essential \
        gcc \
        git \
        libffi-dev \
        libssl-dev

WORKDIR /wheels
RUN git clone https://github.com/hass-emulated-hue/core.git /app \
    && cp /app/requirements.txt requirements.txt

# build python wheels
RUN pip wheel uvloop cchardet aiodns brotlipy \
    && pip wheel -r requirements.txt

# Download and extract s6 overlay
FROM alpine:latest as s6downloader
WORKDIR /s6downloader

RUN OVERLAY_VERSION=$(wget --no-check-certificate -qO - https://api.github.com/repos/just-containers/s6-overlay/releases/latest | awk '/tag_name/{print $4;exit}' FS='[""]') \
    && wget -O s6-overlay.tar.gz "https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-amd64.tar.gz" \
    && tar xfz s6-overlay.tar.gz \
    && rm s6-overlay.tar.gz

FROM alpine:latest as bashiodownloader
WORKDIR /bashio

RUN wget -O /tmp/bashio.tar.gz "https://github.com/hassio-addons/bashio/archive/v0.9.0.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
        /tmp/bashio.tar.gz \
        --strip 1 -C /tmp/bashio \
    && mv /tmp/bashio/lib .

#### FINAL IMAGE
FROM python:3.8-slim AS base-image

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_KEEP_ENV=1 \
    DEBIAN_FRONTEND="noninteractive"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        jq \
        openssl \
        tzdata \
    # cleanup
    && rm -rf /tmp/* \
    && rm -rf /var/lib/apt/lists/*

# Install bashio
RUN --mount=type=bind,target=/bashio,source=/bashio,from=bashiodownloader,rw \
    mv /bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio

# Install s6 overlay
COPY --from=s6downloader /s6downloader /

# https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/syntax.md#build-mounts-run---mount
# Install pip dependencies with built wheels
RUN --mount=type=bind,target=/wheels,source=/wheels,from=wheels-builder,rw \
    pip install --no-cache-dir -f /wheels -r /wheels/requirements.txt

# Install services
COPY rootfs /

LABEL \
    io.hass.name="Hass Emulated Hue" \
    io.hass.description="Hue Emulation for Home Assistant" \
    io.hass.arch="${HASS_ARCH}" \
    io.hass.type="addon"

CMD ["/init"]