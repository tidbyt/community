#!/bin/bash

set -e

# Install libwebp.
sudo apt-get install -y libwebp-dev

# Download and install pixlet.
PIXLET_VERSION=`cat go.mod | grep 'require tidbyt.dev/pixlet' | cut -d ' ' -f 3 | sed 's/v//'`
curl -LO "https://github.com/tidbyt/pixlet/releases/download/v${PIXLET_VERSION}/pixlet_${PIXLET_VERSION}_linux_amd64.tar.gz"
sudo tar -C /usr/local/bin -xvf "pixlet_${PIXLET_VERSION}_linux_amd64.tar.gz"
rm "pixlet_${PIXLET_VERSION}_linux_amd64.tar.gz"