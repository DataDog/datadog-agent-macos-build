#!/bin/bash -e

# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/)
# Copyright 2022-present Datadog, Inc.

# FIXME: Uncomment this once we fix the way we cache the builder setup
# in datadog-agent-macos-build, we have non-critical errors that make
# the script fail with set -e.
# set -e


# Does an omnibus build of the Agent.

# Prerequisites:
# - clone_agent.sh has been run
# - builder_setup.sh has been run
# - $VERSION contains the datadog-agent git ref to target
# - $RELEASE_VERSION contains the release.json version to package. Defaults to $VERSION
# - $AGENT_MAJOR_VERSION contains the major version to release
# - $PYTHON_RUNTIMES contains the included python runtimes
# - $SIGN set to true if signing is enabled
# - if $SIGN is set to true:
#   - $KEYCHAIN_NAME contains the keychain name. Defaults to login.keychain
#   - $KEYCHAIN_PWD contains the keychain password

export RELEASE_VERSION=${RELEASE_VERSION:-$VERSION}
export KEYCHAIN_NAME=${KEYCHAIN_NAME:-"login.keychain"}

# Load build setup vars
source ~/.build_setup
cd $GOPATH/src/github.com/DataDog/datadog-agent

# Install python deps (invoke, etc.)
python3 -m pip install -r requirements.txt

# Clean up previous builds
sudo rm -rf /opt/datadog-agent ./vendor ./vendor-new /var/cache/omnibus/src/* ./omnibus/Gemfile.lock

# Create target folders
sudo mkdir -p /opt/datadog-agent /var/cache/omnibus && sudo chown "$USER" /opt/datadog-agent /var/cache/omnibus

inv check-go-version || exit 1

# Update the INTEGRATION_CORE_VERSION if requested
if [ -n "$INTEGRATIONS_CORE_REF" ]; then
    export INTEGRATIONS_CORE_VERSION="$INTEGRATIONS_CORE_REF"
fi

INVOKE_TASK="omnibus.build"
if ! inv --list | grep -qF "$INVOKE_TASK"; then
    echo -e "\033[0;31magent.omnibus-build is deprecated. Please use omnibus.build!\033[0m"
    INVOKE_TASK="agent.omnibus-build"
fi

export OMNIBUS_GIT_CACHE_DIR=/tmp/omnibus-git-cache

# Launch omnibus build
if [ "$SIGN" = "true" ]; then
    # Unlock the keychain to get access to the signing certificates
    security unlock-keychain -p "$KEYCHAIN_PWD" "$KEYCHAIN_NAME"
    inv -e $INVOKE_TASK --hardened-runtime --python-runtimes "$PYTHON_RUNTIMES" --major-version "$AGENT_MAJOR_VERSION" --release-version "$RELEASE_VERSION" || exit 1
    # Lock the keychain once we're done
    security lock-keychain "$KEYCHAIN_NAME"
else
    inv -e $INVOKE_TASK --skip-sign --python-runtimes "$PYTHON_RUNTIMES" --major-version "$AGENT_MAJOR_VERSION" --release-version "$RELEASE_VERSION" || exit 1
fi
