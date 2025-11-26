#!/bin/bash

set -e   # Exit immediately if any command fails

# # Clean up TARGETS: remove quotes and extra spaces
TARGETS=$(echo ${TARGETS} | tr -d '"' | awk '{$1=$1};1')

#  List of apps that need custom max render times (slow on cold cache)
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

# If TARGETS is empty, nothing to check
if [ -z "${TARGETS}" ]; then
    echo "✔️ No apps modified"
    exit 0
fi

# Loop through each target app
for target in ${TARGETS}; do

# Skip if the app folder no longer exists (deleted)
    if [[ ! -d "$target" ]]; then
	# app was deleted
	continue
    fi

 # If the app has a custom runtime exception, use it
    if [ ${runtime_exceptions[$target]} ]; then
	t=${runtime_exceptions[$target]}
	echo "pixlet check --max-render-time ${t} ${target}"
	pixlet check --max-render-time ${t} ${target}

 # Otherwise use the default pixlet check
    else
	echo "pixlet check ${target}"
	pixlet check ${target}
    fi
done
