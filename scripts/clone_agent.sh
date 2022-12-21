#!/bin/bash

mkdir -p $HOME/go
echo 'export GOPATH=$HOME/go' >> ~/.build_setup
echo 'export PATH="$GOPATH/bin:$PATH"' >> ~/.build_setup

source ~/.build_setup

# Clone the repo
mkdir -p $GOPATH/src/github.com/DataDog && cd $GOPATH/src/github.com/DataDog
git clone https://github.com/DataDog/datadog-agent || true # git clone fails if the datadog-agent re    po is already there
