FROM hassioaddons/base-python as wheels-builder

ENV PIP_EXTRA_INDEX_URL=https://www.piwheels.org/simple

# Install buildtime packages
RUN apk add --no-cache \
        build-base \
        cmake \
        libuv-dev \
        libffi-dev \
        python3-dev \
        openssl-dev \
        git \
        openssl

WORKDIR /wheels
RUN git clone https://github.com/hass-emulated-hue/core.git /app \
    && cp /app/requirements.txt requirements.txt

# build python wheels
RUN pip wheel uvloop cchardet aiodns brotlipy \
    && pip wheel -r requirements.txt
    
#### FINAL IMAGE
FROM hassioaddons/base-python AS base-image

RUN apk add --no-cache \
        curl \
        tzdata \
        ca-certificates \
        openssl

# https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/syntax.md#build-mounts-run---mount
RUN --mount=type=bind,target=/wheels,source=/wheels,from=wheels-builder,rw \
    pip install --no-cache-dir -f /wheels -r /wheels/requirements.txt
