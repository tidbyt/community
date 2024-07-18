#!/bin/bash

set -e

# Trim quotes in case any were introduced.
TARGETS=$(echo ${TARGETS} | tr -d '"' | awk '{$1=$1};1')

# Override the max runtime for specific apps. This is useful for apps
# that have a longer runtime on cold cache, but perform well when it's
# warm. Should add exceptions sparingly.
declare -A runtime_exceptions
runtime_exceptions["apps/cltlightrail"]="2s"
runtime_exceptions["apps/milbscores"]="15s"
runtime_exceptions["apps/ncaafscores"]="5s"
runtime_exceptions["apps/ncaafstandings"]="5s"
runtime_exceptions["apps/ncaamstandings"]="5s"
runtime_exceptions["apps/ncaanowstandings"]="5s"
runtime_exceptions["apps/ncaanowstandings"]="5s"
runtime_exceptions["apps/ncaawstandings"]="5s"
runtime_exceptions["apps/nflstandings"]="5s"
runtime_exceptions["apps/nhlstandings"]="5s"

if [ -z "${TARGETS}" ]; then
    echo "✔️ No apps modified"
    exit 0
fi

for target in ${TARGETS}; do
    if [[ ! -d "$target" ]]; then
	# app was deleted
	continue
    fi

    if [ ${runtime_exceptions[$target]} ]; then
	t=${runtime_exceptions[$target]}
	echo "pixlet check --max-render-time ${t} ${target}"
	pixlet check --max-render-time ${t} ${target}
    else
	echo "pixlet check ${target}"
	pixlet check ${target}
    fi
done
