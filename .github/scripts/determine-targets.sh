#!/bin/bash

set -e

# Determine base commit.
echo "GITHUB_BASE_REF=${GITHUB_BASE_REF}"
echo "GITHUB_HEAD_REF=${GITHUB_HEAD_REF}"
echo "BASE_SHA=${BASE_SHA}"
echo "GITHUB_SHA=${GITHUB_SHA}"

# Determine targets.
echo "OLD_COMMIT=${BASE_SHA}"
echo "NEW_COMMIT=${GITHUB_SHA}"
TARGETS="$(pixlet community target-determinator --old ${OLD_COMMIT} --new ${NEW_COMMIT})"

# Convert new lines to spaces. Maybe Pixlet should do this?
TARGETS="$(echo "${TARGETS}" | tr "\n" " ")"
echo "${TARGETS}"

# Record output to GitHub variable.
printf 'targets="%s"' "${TARGETS}" >> ${GITHUB_OUTPUT}