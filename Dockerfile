# build syslog-stdout in a separate container (pinned to a known-good commit
# corresponding to the 1.1.1 release)
FROM golang:1-alpine AS builder
RUN apk add --no-cache git musl-dev gcc && \
  git clone https://github.com/timonier/syslog-stdout /go/src/github.com/timonier/syslog-stdout && \
  git -C /go/src/github.com/timonier/syslog-stdout checkout 026971e18bbc8c0ce289abb3c5da1bbf3e2de523 && \
  go build -ldflags '-s -w -linkmode external -extldflags -static' -o /usr/bin/syslog-stdout github.com/timonier/syslog-stdout/src

################################################################################

FROM debian:stretch-slim

ENV PATH=/opt/venv/bin:$PATH

COPY --from=builder /usr/bin/syslog-stdout /usr/bin/
COPY . /opt/swift

# give --build-arg BUILD_MODE=sap to install components required by required by
# the Helm chart at https://github.com/sapcc/helm-charts/tree/master/openstack/swift
ARG BUILD_MODE=normal

RUN /opt/swift/docker/build.sh
