#!/bin/bash

set -e

echo $GITHUB_BASE_REF
echo $GITHUB_HEAD_REF
echo $GITHUB_SHA

NEW_COMMIT=${GITHUB_SHA}
OLD_COMMIT=`git log --pretty=format:"%h" ${GITHUB_BASE_REF}..${GITHUB_HEAD_REF}`
echo $OLD_COMMIT
echo $NEW_COMMIT