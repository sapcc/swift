# build syslog-stdout in a separate container
FROM golang:1-alpine AS builder
RUN apk add --no-cache git musl-dev gcc make
RUN git clone https://github.com/sapcc/syslog-stdout /go/src/github.com/sapcc/syslog-stdout && \
    go build -ldflags '-s -w -linkmode external -extldflags -static' -o /usr/bin/syslog-stdout github.com/sapcc/syslog-stdout/src
RUN git clone https://github.com/sapcc/swift-health-exporter && \
    make -C ./swift-health-exporter install PREFIX=/pkg GO_BUILDFLAGS='-mod vendor'


################################################################################

FROM debian:stretch-slim

ENV PATH=/opt/venv/bin:$PATH

COPY --from=builder /usr/bin/syslog-stdout /usr/bin/
COPY --from=builder /pkg/bin/swift-health-exporter /usr/bin/
COPY . /opt/swift

# give --build-arg BUILD_MODE=sap to install components required by required by
# the Helm chart at https://github.com/sapcc/helm-charts/tree/master/openstack/swift
ARG BUILD_MODE=normal

RUN /opt/swift/docker/build.sh
