#!/bin/bash

# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/)
# Copyright 2022-present Datadog, Inc.

# FIXME: Uncomment this once the build script is fixed, and we
# check that this script doesn't accidentally exit early with set -e.

# set -e

# Requests notarization of the Agent package to Apple.

# Prerequisites:
# - you need a host running MacOS >= 10.13.6, with XCode >= 10.1 installed.
# - xpath installed and in $PATH (it should be installed by default).
# - builder_setup.sh has been run with SIGN=true.
# - the artifact is stored in $GOPATH/src/github.com/DataDog/datadog-agent/omnibus/pkg/.
# - $RELEASE_VERSION contains the version that was created. Defaults to $VERSION.
# - $APPLE_ACCOUNT contains the Apple account name for the Agent.
# - $NOTARIZATION_PWD contains the app-specific notarization password for the Agent.

# Load build setup vars
source ~/.build_setup

export RELEASE_VERSION=${RELEASE_VERSION:-$VERSION}

unset REQUEST_UUID
unset NOTARIZATION_STATUS_CODE
unset LATEST_DMG

# Find latest .dmg file in $GOPATH/src/github.com/Datadog/datadog-agent/omnibus/pkg
for file in "$GOPATH/src/github.com/Datadog/datadog-agent/omnibus/pkg"/*.dmg; do
  if [[ -z "$LATEST_DMG" || "$file" -nt "$LATEST_DMG" ]]; then LATEST_DMG="$file"; fi
done

echo "File to upload: $LATEST_DMG"

# Send package for notarization; retrieve REQUEST_UUID
echo "Sending notarization request."

# Example notarization request output:
# <?xml version="1.0" encoding="UTF-8"?>
# <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
# <plist version="1.0">
# <dict>
#         <key>notarization-upload</key>
#         <dict>
#                 <key>RequestUUID</key>
#                 <string>wwwwwwww-xxxx-yyyy-zzzz-tttttttttttt</string>
#         </dict>
#         <key>os-version</key>
#         <string>10.14.6</string>
#         <key>success-message</key>
#         <string>No errors uploading '/path/to/file'.</string>
#         <key>tool-path</key>
#         <string>/Applications/Xcode.app/Contents/SharedFrameworks/ContentDeliveryServices.framework/Versions/A/Frameworks/AppStoreService.framework</string>
#         <key>tool-version</key>
#         <string>4.00.1181</string>
# </dict>
# </plist>

xcrun altool submit --apple-id "$APPLE_ACCOUNT" --password "$NOTARIZATION_PWD" "$LATEST_DMG" --wait

