#!/bin/bash

# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/)
# Copyright 2022-present Datadog, Inc.

set -e

# Requests notarization of the Agent package to Apple.

# Prerequisites:
# - you need a host running MacOS >= 10.15
# - Xcode 13+ or a manual install of notarytool see
#   (https://developer.apple.com/documentation/technotes/tn3147-migrating-to-the-latest-notarization-tool#Enable-notarization-on-an-older-version-of-macOS)
# - the artifact is stored in $GOPATH/src/github.com/DataDog/datadog-agent/omnibus/pkg/.
# - $APPLE_ACCOUNT contains the Apple account name for the Agent.
# - $NOTARIZATION_PWD contains the app-specific notarization password for the Agent.

# Load build setup vars
source ~/.build_setup

export RELEASE_VERSION=${RELEASE_VERSION:-$VERSION}

unset LATEST_DMG

# Find latest .dmg file in $GOPATH/src/github.com/Datadog/datadog-agent/omnibus/pkg
for file in "$GOPATH/src/github.com/Datadog/datadog-agent/omnibus/pkg"/*.dmg; do
  if [[ -z "$LATEST_DMG" || "$file" -nt "$LATEST_DMG" ]]; then LATEST_DMG="$file"; fi
done

echo "File to upload: $LATEST_DMG"

# Send package for notarization; retrieve REQUEST_UUID
echo "Sending notarization request."

RESULT=$(xcrun notarytool submit --apple-id "$APPLE_ACCOUNT" --team-id "$TEAM_ID" --password "$NOTARIZATION_PWD" "$LATEST_DMG" --wait)
EXIT_CODE=$?
echo "Results: $RESULT"
SUBMISSION_ID=$(echo "$RESULT" | awk '$1 == "id:"{print $2; exit}')
echo "Submission ID: $SUBMISSION_ID"
echo "Submission logs:"
xcrun notarytool log --apple-id "$APPLE_ACCOUNT" --team-id "$TEAM_ID" --password "$NOTARIZATION_PWD" "$SUBMISSION_ID"
# Once we have some logs, propagate potential failures
exit $EXIT_CODE
