#!/bin/bash

# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/)
# Copyright 2022-present Datadog, Inc.

set -e

# Setups a MacOS builder that can do unsigned builds of the MacOS Agent.
# The .build_setup file is populated with the correct envvar definitions to do the build,
# which are then used by the build script.

# Prerequisites:
# - A MacOS 10.13.6 (High Sierra) box
# - clone_agent.sh has been run


# About brew packages:
# We use a custom homebrew tap (DataDog/datadog-agent-macos-build, hosted in https://github.com/DataDog/homebrew-datadog-agent-macos-build)
# to keep pinned versions of the software we need.

# How to update a version of a brew package:
# 1. See the instructions of the DataDog/homebrew-datadog-agent-macos-build repo
#    to add a formula for the new version you want to use.
# 2. Update here the version of the formula to use.

source ~/.build_setup

export PKG_CONFIG_VERSION=0.29.2
export RUBY_VERSION=2.7.4
export BUNDLER_VERSION=2.3.18
export PYTHON_VERSION=3.11.5
export RUST_VERSION=1.74.0
export RUSTUP_VERSION=1.25.1
# Pin cmake version without sphinx-doc, which causes build issues
export CMAKE_VERSION=3.18.2.2
export GIMME_VERSION=1.5.4

export GO_VERSION=$(cat $GOPATH/src/github.com/DataDog/datadog-agent/.go-version)
# Newer version of IBM_MQ have a different name
export IBM_MQ_VERSION=9.2.4.0-IBM-MQ-DevToolkit
#export IBM_MQ_VERSION=9.2.2.0-IBM-MQ-Toolkit

# Install or upgrade brew (will also install Command Line Tools)

# NOTE: The macOS runner has HOMEBREW_NO_INSTALL_FROM_API set, which makes it
# try to clone homebrew-core. At one point, cloning of homebrew-core started
# returning the following error for us in about 50 % of cases:
#     remote: fatal: object 80a071c049c4f2e465e0b1c40cfc6325005ab05b cannot be read
#     remote: aborting due to possible repository corruption on the remote side.
# Unsetting HOMEBREW_NO_INSTALL_FROM_API makes brew use formulas from
# https://formulae.brew.sh/, thus avoiding cloning the repository, hence
# avoiding the error.
brew untap --force homebrew/cask
rm -rf /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core
unset HOMEBREW_NO_INSTALL_FROM_API

CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# Add our custom repository
brew tap DataDog/datadog-agent-macos-build

brew uninstall python@2 -f || true # Uninstall python 2 if present
brew uninstall python -f || true # Uninstall python 3 if present

# Install cmake
brew install DataDog/datadog-agent-macos-build/cmake@$CMAKE_VERSION -f
brew link --overwrite cmake@$CMAKE_VERSION

# Install pkg-config
brew install DataDog/datadog-agent-macos-build/pkg-config@$PKG_CONFIG_VERSION -f
brew link --overwrite pkg-config@$PKG_CONFIG_VERSION

# Install ruby (depends on pkg-config)
brew install DataDog/datadog-agent-macos-build/ruby@$RUBY_VERSION -f
brew link --overwrite ruby@$RUBY_VERSION

gem install bundler -v $BUNDLER_VERSION -f

# Install python
# "brew link --overwrite" will refuse to overwrite links it doesn't own,
# so we have to make sure these don't exist
# see: https://github.com/actions/setup-python/issues/577
rm -f /usr/local/bin/2to3 \
      /usr/local/bin/idle3 \
      /usr/local/bin/pydoc3 \
      /usr/local/bin/python3 \
      /usr/local/bin/python3-config
brew install DataDog/datadog-agent-macos-build/python@$PYTHON_VERSION -f
brew link --overwrite python@$PYTHON_VERSION

# Install rust
# Rust may be needed to compile some python libs
curl -sSL -o rustup-init https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-apple-darwin/rustup-init \
    && chmod +x ./rustup-init \
    && ./rustup-init -y --profile minimal --default-toolchain ${RUST_VERSION} \
    && rm ./rustup-init

# Install gimme
brew install DataDog/datadog-agent-macos-build/gimme@$GIMME_VERSION -f
brew link --overwrite gimme@$GIMME_VERSION
eval `gimme $GO_VERSION`
echo 'eval `gimme '$GO_VERSION'`' >> ~/.build_setup

# Install IBM MQ
sudo mkdir -p /opt/mqm
curl --retry 5 --fail "https://s3.amazonaws.com/dd-agent-omnibus/ibm-mq-backup/${IBM_MQ_VERSION}-MacX64.pkg" -o /tmp/mq_client.pkg
sudo installer -pkg /tmp/mq_client.pkg -target /
sudo rm -rf /tmp/mq_client.pkg
