# MacOS datadog-agent build Github Action

This repository stores the scripts and Github Action necessary to perform a MacOS Agent build.

## Purpose

macOS Datadog Agent builds are done automatically via a Github Action in this repository.

`datadog-agent` release pipelines contain jobs (`agent_dmg-x64-a6` and `agent_dmg-x64-a7`) that trigger runs of the Github Action, using the [agent-macos-build](https://github.com/apps/agent-macos-build) Github App, and fetch the job artifacts from the Github Action. These build artifacts are then deposited in a staging S3 bucket (`dd-agent-macostesting`).

The Github Action uses our [custom Homebrew tap](https://github.com/DataDog/homebrew-datadog-agent-macos-build) to fetch brew formulae, and has a [`datadog-agent-buildimages` repo](https://github.com/DataDog/datadog-agent-buildimages) submodule to setup the MacOS runner.

The `datadog-agent-buildimages` submodule is kept up-to-date using `dependabot`.
