#!/bin/bash -e

set -e

# Fetches the datadog-agent repo, checks out to the requested version
# and runs the unit tests

# Prerequisites:
# - builder_setup.sh has been run
# - $VERSION contains the datadog-agent git ref to target
# - $PYTHON_RUNTIMES contains the included python runtimes

# Load build setup vars
source ~/.build_setup

# Clone the repo
mkdir -p $GOPATH/src/github.com/DataDog && cd $GOPATH/src/github.com/DataDog
git clone https://github.com/DataDog/datadog-agent || true # git clone fails if the datadog-agent repo is already there
cd $GOPATH/src/github.com/DataDog/datadog-agent

# Checkout to correct version
git pull
git checkout "$VERSION"
git rev-parse HEAD

# Install python deps (invoke, etc.)
python3 -m pip install -r requirements.txt

# Install dependencies
inv -e install-tools
inv -e deps

# Run rtloader test
inv -e rtloader.make --python-runtimes $PYTHON_RUNTIMES
inv -e rtloader.install
# FIXME: rtloader tests fail on Mac with "image not found" errors
#inv -e rtloader.test

# Run unit tests
inv -e test --rerun-fails=2 --python-runtimes $PYTHON_RUNTIMES --coverage --race --profile --cpus 3

# Run invoke task tests
python3 -m tasks.release_tests
python3 -m tasks.libs.version_tests
