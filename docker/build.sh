#!/bin/bash
set -euxo pipefail

# install dependencies
apt-get update
apt-get dist-upgrade -y
DEPENDS="netbase ca-certificates curl python virtualenv sudo rsync gettext liberasurecode1 libffi6 libssl1.1 netcat procps lsof iproute2"
MAKEDEPENDS="git virtualenv build-essential python-dev liberasurecode-dev libffi-dev libssl-dev"
apt-get install -y --no-install-recommends ${DEPENDS} ${MAKEDEPENDS}

# create service user
groupadd -g 1000 swift
useradd -u 1000 -g swift -M -d /var/lib/swift -s /usr/sbin/nologin -c "swift user" swift
install -d -m 0755 -o swift -g swift /etc/swift /var/log/swift /var/lib/swift /var/cache/swift

# fetch upper-constraints.txt from openstack/requirements
if [ "${BUILD_MODE}" = sap ]; then
  curl -L -o /root/upper-constraints.txt https://raw.githubusercontent.com/sapcc/requirements/stable/ussuri-m3/upper-constraints.txt
else
  curl -L -o /root/upper-constraints.txt https://raw.githubusercontent.com/sapcc/requirements/stable/ussuri/upper-constraints.txt
fi

# fetching origin to get an up to date tag list
# needed for pbr and a proper swift version string
git -C /opt/swift fetch origin

# setup virtualenv and install Swift there
virtualenv --system-site-packages /opt/venv/
set +ux; source /opt/venv/bin/activate; set -ux
pip_install() {
  pip --no-cache-dir install --upgrade "$@"
}
pip_install pip
pip_install setuptools wheel
pip_install --no-compile -c /root/upper-constraints.txt \
  /opt/swift/ \
  keystonemiddleware \
  python-memcached \
  python-keystoneclient \
  python-swiftclient

# if requested, install components required by the Helm chart at
# https://github.com/sapcc/helm-charts/tree/master/openstack/swift
if [ "${BUILD_MODE}" = sap ]; then
  curl -L -o /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64
  chmod +x /usr/bin/dumb-init

  pip_install --no-compile -c /root/upper-constraints.txt \
    git+https://github.com/sapcc/swift-account-caretaker.git \
    git+https://github.com/sapcc/swift-addons.git \
    git+https://github.com/sapcc/swift-sentry.git \
    git+https://github.com/sapcc/openstack-watcher-middleware.git@1.0.30 \
    git+https://github.com/sapcc/openstack-rate-limit-middleware.git@1.1.0

  # https://github.com/openstack/keystonemiddleware/commit/f6037a3d50a80d8c2e0044c8f72d23dddb0d7203
  # Introduces the option to specify the interface for keystone, no need to patch that anymore
  # apply keystonemiddleware patch
  #(
  #  cd /opt/venv/lib/python2.7/site-packages && patch -p0
  #) < /opt/swift/docker/keystonemiddleware-token-validation-interface.patch

  # startup logic and unmount helper
  install -D -m 0755 -t /usr/bin/ /opt/swift/docker/bin/*
fi

# cleanup
apt-get purge -y --auto-remove ${MAKEDEPENDS}
rm -rf /var/lib/apt/lists/*

rm -rf /tmp/* /root/.cache
find /usr/ /var/ -type f -name '*.pyc' -delete
