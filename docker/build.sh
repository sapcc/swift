#!/bin/bash
set -euxo pipefail

# install dependencies
apt-get update
apt-get dist-upgrade -y
DEPENDS="netbase ca-certificates python virtualenv sudo rsync gettext liberasurecode1 libffi6 libssl1.1"
MAKEDEPENDS="git virtualenv build-essential python-dev liberasurecode-dev libffi-dev libssl-dev"
apt-get install -y --no-install-recommends ${DEPENDS} ${MAKEDEPENDS}

# create service user
groupadd -g 1001 swift
useradd -u 1001 -g swift -M -d /var/lib/swift -s /usr/sbin/nologin -c "swift user" swift
install -d -m 0755 -o swift -g swift /etc/swift /var/log/swift /var/lib/swift /var/cache/swift

# setup virtualenv and install Swift there
virtualenv --system-site-packages /opt/venv/
set +ux; source /opt/venv/bin/activate; set -ux
pip install -U pip
pip install -U setuptools wheel
pip install --no-cache-dir --no-compile /opt/swift/

# cleanup
apt-get purge -y --auto-remove ${MAKEDEPENDS}
rm -rf /var/lib/apt/lists/*

rm -rf /tmp/* /root/.cache
find /usr/ /var/ -type f -name "*.pyc" -delete
