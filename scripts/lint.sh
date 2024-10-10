#!/bin/bash -e

# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/)
# Copyright 2022-present Datadog, Inc.

set -e

# Fetches the datadog-agent repo, checks out to the requested version
# and lints the code

# Prerequisites:
# - clone_agent.sh has been run
# - builder_setup.sh has been run
# - $VERSION contains the datadog-agent git ref to target
# - $PYTHON_RUNTIMES contains the included python runtimes

# Load build setup vars
source ~/.build_setup
cd "$GOPATH"/src/github.com/DataDog/datadog-agent

# Install python deps (invoke, etc.)

# Python 3.12 changes default behavior how packages are installed.
# In particular, --break-system-packages command line option is 
# required to use the old behavior or use a virtual env. https://github.com/actions/runner-images/issues/8615
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt

# Install dependencies
inv -e install-tools
inv -e deps

# Run go linters
inv -e linter.go --cpus 4 --timeout 60

