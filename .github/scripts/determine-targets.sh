#!/bin/bash

set -e

# Determine targets.
OLD_COMMIT=$(git rev-list --parents -n 1 ${GITHUB_SHA} | cut -d " " -f 2)
echo "OLD_COMMIT=${OLD_COMMIT}"

NEW_COMMIT=$(git rev-list --parents -n 1 ${GITHUB_SHA} | cut -d " " -f 3)
echo "NEW_COMMIT=${NEW_COMMIT}"

TARGETS="$(pixlet community target-determinator --old ${OLD_COMMIT} --new ${NEW_COMMIT})"

# Convert new lines to spaces. Maybe Pixlet should do this?
TARGETS="$(echo "${TARGETS}" | tr "\n" " ")"
echo "${TARGETS}"

# Record output to GitHub variable.
echo "targets=${TARGETS}" >> ${GITHUB_OUTPUT}