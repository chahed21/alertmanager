#!/bin/sh

sed -i 's/MARKET_LABEL/'"$MARKET_LABEL"'/g' /etc/alertmanager/config.yml

#todo move source environment configuration from Prometheus to here

exec /bin/alertmanager "$@"

LOG_LEVEL="${LOG_LEVEL:-info}"

exec /bin/alertmanager "$@" --log.level="$LOG_LEVEL"
