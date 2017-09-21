FROM debian:stretch-slim

ENV PATH=/opt/venv/bin:$PATH

ADD . /opt/swift

RUN /opt/swift/docker/build.sh
