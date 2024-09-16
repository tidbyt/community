#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

set -e

# This script will install the latest released version of pixlet,
# Unless this argument is set to a specific version tag
# e.g. v0.22.7
PIN_VERSION_TAG="v0.22.7"

cd /tmp

echo "::install libwebp-dev::"
sudo apt update -y
sudo apt -y install libwebp-dev 

echo "::install pixlet::"

if [ -z "$PIN_VERSION_TAG" ]; then
    TAG=$(git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' https://github.com/tidbyt/pixlet.git | tail -n1  | cut --delimiter='/' --fields=3)
else
    TAG="$PIN_VERSION_TAG"
fi

echo "Installing version ${TAG}"
# Version without leading v 
VERSION=${TAG:1}

URL="https://github.com/tidbyt/pixlet/releases/download/${TAG}/pixlet_${VERSION}_linux_amd64.tar.gz"

wget -O pixlet.tar.gz $URL
tar -xzf pixlet.tar.gz pixlet
sudo mv pixlet /usr/local/bin/

echo "::Validate Pixlet Installed::"
pixlet version