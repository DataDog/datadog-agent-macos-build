#!/bin/bash

# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/)
# Copyright 2022-present Datadog, Inc.

# Clones the datadog-agent repository, and switches to the target branch

# Prerequisites:
# - $VERSION contains the datadog-agent git ref to target

mkdir -p $HOME/go
echo 'export GOPATH=$HOME/go' >> ~/.build_setup
echo 'export PATH="$GOPATH/bin:$PATH"' >> ~/.build_setup

source ~/.build_setup

# Clone the repo
mkdir -p $GOPATH/src/github.com/DataDog && cd $GOPATH/src/github.com/DataDog
GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999 git clone https://github.com/DataDog/datadog-agent || true # git clone fails if the datadog-agent repo is already there

cd $GOPATH/src/github.com/DataDog/datadog-agent

# Checkout to correct version
git pull
git checkout "$VERSION"
