#!/bin/bash

set -e

# Trim quotes in case any were introduced.
TARGETS=$(echo ${TARGETS} | tr -d '"' | awk '{$1=$1};1')

# If there are no targets, return early.
if [ -z "${TARGETS}" ]; then
    echo "✔️ No apps modified"
    exit 0
fi

# Deploy targets
for TARGET in ${TARGETS}; do
    echo "Using target ${TARGET}"
    TARGET=${TARGET%/}
    APP_ID=$(cat ${TARGET}/manifest.yaml | grep 'id:' | cut -d " " -f 2)

    echo "Deploying ${APP_ID} at ${VERSION}"
    pixlet bundle ${TARGET} -o ${TARGET}
    pixlet upload ${TARGET}/bundle.tar.gz --app ${APP_ID} --version ${VERSION}
    pixlet deploy --app ${APP_ID} --version ${VERSION}
done
