#!/usr/bin/with-contenv bashio
# ==============================================================================
# Community Hass.io Add-ons: Emulated Hue
# This file defines environment variables based on user specified config options
# ==============================================================================

if bashio::config.has_value 'data'; then
    export DATA_DIR=$(bashio::config 'data')
fi

if bashio::config.has_value 'url'; then
    export HASS_URL=$(bashio::config 'url')
fi

if bashio::config.has_value 'token'; then
    export HASS_TOKEN=$(bashio::config 'token')
fi

if bashio::config.has_value 'verbose'; then
    export VERBOSE=$(bashio::config 'verbose')
fi
