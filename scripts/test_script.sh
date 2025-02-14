#!/bin/bash -e

# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/)
# Copyright 2022-present Datadog, Inc.

set -e

# Fetches the datadog-agent repo, checks out to the requested version
# and runs the unit tests

# Prerequisites:
# - clone_agent.sh has been run
# - builder_setup.sh has been run
# - $VERSION contains the datadog-agent git ref to target
# - $PYTHON_RUNTIMES contains the included python runtimes

# Load build setup vars
source ~/.build_setup
cd $GOPATH/src/github.com/DataDog/datadog-agent

# Install python deps (invoke, etc.)

# Python 3.12 changes default behavior how packages are installed.
# In particular, --break-system-packages command line option is
# required to use the old behavior or use a virtual env. https://github.com/actions/runner-images/issues/8615
python3 -m venv .venv
source .venv/bin/activate

DEVA_VERSION="$(curl -s https://raw.githubusercontent.com/DataDog/datadog-agent-buildimages/main/deva.env | awk -F= '/^DEVA_VERSION=/ {print $2}')"
python3 -m pip install "git+https://github.com/DataDog/datadog-agent-dev.git@${DEVA_VERSION}"
deva -v self dep sync -f legacy-tasks -f legacy-github

# Install dependencies
deva inv -e install-tools
deva inv -e deps

# Run rtloader test
deva inv -e rtloader.make
deva inv -e rtloader.install
# FIXME: rtloader tests fail on Mac with "image not found" errors
#inv -e rtloader.test

deva inv -e agent.build

FAST_TESTS_FLAG=""
if [ "$FAST_TESTS" = "true" ]; then FAST_TESTS_FLAG="--only-impacted-packages"; fi

TEST_WASHER_FLAG=""
if [ "$TEST_WASHER" = "true" ]; then TEST_WASHER_FLAG="--test-washer"; fi

# Run unit tests
deva inv -e test --rerun-fails=2 --race --profile --cpus 4 --save-result-json "test_output.json" --junit-tar "junit-tests_macos.tgz" $FAST_TESTS_FLAG $TEST_WASHER_FLAG

# Run invoke task tests
deva inv -e invoke-unit-tests.run

# Upload coverage reports to Codecov. Never fail on coverage upload.
deva inv -e codecov || true
