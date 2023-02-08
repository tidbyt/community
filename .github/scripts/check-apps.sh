#!/bin/bash

set -e

# Check apps.
if [ ! -z "${TARGETS}" ]; then
    pixlet check -r ${TARGETS}
else
    echo "✔️ No apps modified"
fi