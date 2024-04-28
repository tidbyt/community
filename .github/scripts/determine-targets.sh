#!/bin/bash

set -e

# Determine base commit.
OLD_COMMIT=$(git merge-base ${BASE_SHA} ${HEAD_SHA})
NEW_COMMIT=${HEAD_SHA}
echo "OLD_COMMIT=${OLD_COMMIT}"
echo "NEW_COMMIT=${NEW_COMMIT}"

# Determine targets.
# Get a list of changed files, extract the unique directory names under 'apps/'
TARGETS=$(git diff --name-only $OLD_COMMIT $NEW_COMMIT | grep '^apps/' | cut -d'/' -f1-2 | sort -u)
echo "Modified targets: ${TARGETS}"

# Format TARGETS as a space-separated list
TARGETS=$(echo $TARGETS | tr '\n' ' ')

# Record output to GitHub variable.
printf 'targets="%s"' "${TARGETS}" >> ${GITHUB_OUTPUT}
