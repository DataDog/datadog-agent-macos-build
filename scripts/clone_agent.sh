#!/bin/bash

# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/)
# Copyright 2022-present Datadog, Inc.

# Clones the datadog-agent repository, and switches to the target branch

# Prerequisites:
# - $VERSION contains the datadog-agent git ref to target

# Git command that will run up to 3 times before failing
git_with_retries()
{
    for i in 1 2 3; do
        git "$@"
        status=$?
        if [ $status -ne 0 ]; then
            echo "Failed to run git $1 command"

            if [ $i -lt 3 ]; then
                echo "Retrying in 5 seconds..."
                sleep 5
            fi
        else
            # Worked, no need to retry
            break
        fi
    done

    return $status
}

mkdir -p $HOME/go
echo 'export GOPATH=$HOME/go' >> ~/.build_setup
echo 'export PATH="$GOPATH/bin:$PATH"' >> ~/.build_setup

source ~/.build_setup

# Seems to prevent clone failure see
# https://app.datadoghq.com/incidents/33043
git config --global http.postBuffer 524288000

# Clone the repo
mkdir -p $GOPATH/src/github.com/DataDog && cd $GOPATH/src/github.com/DataDog
if ! [ -d $GOPATH/src/github.com/DataDog/datadog-agent ]; then
    git_with_retries clone https://github.com/DataDog/datadog-agent
fi

cd $GOPATH/src/github.com/DataDog/datadog-agent

# Checkout to correct version
git_with_retries pull
# git_with_retries checkout "$VERSION"
git_with_retries checkout celian/build-macos-gitlabci-acix-550
