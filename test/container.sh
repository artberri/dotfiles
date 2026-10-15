#!/bin/sh
#
# Entry point for Linux CI containers (run as root): set up what a fresh
# desktop install would have, create a regular user with sudo, and run
# test/install-twice.sh as that user, like a person would.
#
# Usage: docker run --rm -v "$PWD:/src:ro" <image> sh /src/test/container.sh

set -eu

if command -v apt-get >/dev/null 2>&1; then
	apt-get update -qq
	DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
		sudo curl ca-certificates xz-utils fontconfig openssh-client git >/dev/null
elif command -v dnf >/dev/null 2>&1; then
	dnf install -y -q sudo util-linux shadow-utils curl xz fontconfig openssh-clients git >/dev/null
fi

useradd -m -s /bin/bash dev
echo 'dev ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/dev
cp -r /src /home/dev/.dotfiles
chown -R dev: /home/dev/.dotfiles

su - dev -c /home/dev/.dotfiles/test/install-twice.sh
