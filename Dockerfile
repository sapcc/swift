# build syslog-stdout in a separate container
FROM golang:1-alpine AS builder
RUN apk add --no-cache git musl-dev gcc make
RUN git clone https://github.com/sapcc/syslog-stdout && \
    make -C ./syslog-stdout install PREFIX=/pkg GO_LDFLAGS='-s -w -linkmode external -extldflags -static'
RUN git clone https://github.com/sapcc/swift-health-exporter && \
    make -C ./swift-health-exporter install PREFIX=/pkg GO_LDFLAGS='-s -w -linkmode external -extldflags -static' GO_BUILDFLAGS='-mod vendor'


################################################################################

FROM debian:buster-slim

ENV PATH=/opt/venv/bin:$PATH

COPY --from=builder /pkg/bin/* /usr/bin/
COPY . /opt/swift

# give --build-arg BUILD_MODE=sap to install components required by required by
# the Helm chart at https://github.com/sapcc/helm-charts/tree/master/openstack/swift
ARG BUILD_MODE=normal

RUN /opt/swift/docker/build.sh
