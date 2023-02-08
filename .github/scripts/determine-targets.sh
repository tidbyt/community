#!/bin/bash

set -e

# Determine targets.
echo "OLD_COMMIT=${OLD_COMMIT}"
echo "NEW_COMMIT=${NEW_COMMIT}"
TARGETS="$(pixlet community target-determinator --old ${OLD_COMMIT} --new ${NEW_COMMIT})"

# Convert new lines to spaces. Maybe Pixlet should do this?
TARGETS="$(echo "${TARGETS}" | tr "\n" " ")"
echo "${TARGETS}"

# Record output to GitHub variable.
echo "targets=${TARGETS}" >> ${GITHUB_OUTPUT}