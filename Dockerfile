FROM python:3.8-slim as wheels-builder

ENV PIP_EXTRA_INDEX_URL=https://www.piwheels.org/simple

RUN set -x \
    # Install buildtime packages
    && apt-get update \
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
    
#### FINAL IMAGE
FROM python:3.8-slim AS base-image

RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        tzdata \
        ca-certificates \
        openssl \
    # cleanup
    && rm -rf /tmp/* \
    && rm -rf /var/lib/apt/lists/*

# https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/syntax.md#build-mounts-run---mount
RUN --mount=type=bind,target=/wheels,source=/wheels,from=wheels-builder,rw \
    pip install --no-cache-dir -f /wheels -r /wheels/requirements.txt
