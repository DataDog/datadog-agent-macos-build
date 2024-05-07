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
python3 -m pip install -r requirements.txt
python3 -m pip install -r tasks/libs/requirements-github.txt

# Install dependencies
inv -e install-tools
inv -e deps

# Run rtloader test
inv -e rtloader.make --python-runtimes $PYTHON_RUNTIMES
inv -e rtloader.install
# FIXME: rtloader tests fail on Mac with "image not found" errors
#inv -e rtloader.test

FAST_TESTS_FLAG=""
if [ "$FAST_TESTS" = "true" ]; then FAST_TESTS_FLAG="--only-impacted-packages"; fi

TEST_WASHER_FLAG=""
if [ "$TEST_WASHER" = "true" ]; then TEST_WASHER_FLAG="--test-washer"; fi

# Run unit tests
inv -e test --rerun-fails=2 --python-runtimes $PYTHON_RUNTIMES --race --profile --cpus 3 --save-result-json "test_output.json" --junit-tar "junit-tests_macos.tgz" $FAST_TESTS_FLAG $TEST_WASHER_FLAG

# Run invoke task tests
inv -e invoke-unit-tests

# Upload coverage reports to Codecov. Never fail on coverage upload.
inv -e codecov || true
