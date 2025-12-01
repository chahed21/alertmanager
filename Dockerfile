# Global ARGs (visible to all stages)
ARG OS="linux"
ARG ARCH="amd64"

# ---------------------------------------------------------
# Stage 1 — build binaries
# ---------------------------------------------------------
FROM golang:1.24-alpine AS builder

RUN apk add --no-cache git make gcc g++ musl-dev curl

WORKDIR /src
COPY . .
RUN make common-build

# ---------------------------------------------------------
# Stage 2 — final image
# ---------------------------------------------------------
# Re-declare the ARGs so they are available inside this stage
ARG OS
ARG ARCH

FROM quay.io/prometheus/busybox-${OS}-${ARCH}:latest

LABEL maintainer="The Prometheus Authors <prometheus-developers@googlegroups.com>"
LABEL org.opencontainers.image.source="https://github.com/prometheus/alertmanager"

COPY --from=builder /src/alertmanager /bin/alertmanager
COPY --from=builder /src/amtool       /bin/amtool

# Create directories
RUN mkdir -p /etc/alertmanager /alertmanager && \
    chown -R nobody:nobody /etc/alertmanager /alertmanager && \
    chmod -R g+w /alertmanager

# ---------------------------------------------------------
# ADD YOUR CUSTOM CONFIG & ENTRYPOINT
# ---------------------------------------------------------
COPY docker/config.yml /etc/alertmanager/config.yml
COPY docker/entrypoint.sh /entrypoint.sh

USER root
RUN chmod +x /entrypoint.sh
USER nobody

# Validate config
RUN amtool check-config /etc/alertmanager/config.yml

# ---------------------------------------------------------
# Network, volumes, working dir
# ---------------------------------------------------------
EXPOSE 9093
VOLUME [ "/alertmanager" ]
WORKDIR /alertmanager

# ---------------------------------------------------------
# ENTRYPOINT + CMD = your desired behavior
# ---------------------------------------------------------
ENTRYPOINT ["/entrypoint.sh"]
CMD [ "--config.file=/etc/alertmanager/config.yml", \
"--web.external-url=http://nomad_node:9093/aia/" ]
