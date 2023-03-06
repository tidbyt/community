#!/bin/bash

set -e

# Determine base commit.
OLD_COMMIT=$(git merge-base ${BASE_SHA} ${HEAD_SHA})
NEW_COMMIT=${HEAD_SHA}
echo "OLD_COMMIT=${OLD_COMMIT}"
echo "NEW_COMMIT=${NEW_COMMIT}"

# Determine targets.
TARGETS="$(pixlet community target-determinator --old ${OLD_COMMIT} --new ${NEW_COMMIT})"

# Convert new lines to spaces. Maybe Pixlet should do this?
TARGETS="$(echo "${TARGETS}" | tr "\n" " ")"
echo "${TARGETS}"

# Record output to GitHub variable.
printf 'targets="%s"' "${TARGETS}" >> ${GITHUB_OUTPUT}