# build syslog-stdout in a separate container
FROM golang:1-alpine AS builder
RUN apk add --no-cache git musl-dev gcc make && \
  git clone https://github.com/sapcc/syslog-stdout && \
  make -C ./syslog-stdout install PREFIX=/pkg GO_LDFLAGS='-s -w -linkmode external -extldflags -static'

################################################################################

FROM debian:stretch-slim

ENV PATH=/opt/venv/bin:$PATH

COPY --from=builder /pkg/bin/syslog-stdout /usr/bin/
COPY . /opt/swift

# give --build-arg BUILD_MODE=sap to install components required by required by
# the Helm chart at https://github.com/sapcc/helm-charts/tree/master/openstack/swift
ARG BUILD_MODE=normal

RUN /opt/swift/docker/build.sh
