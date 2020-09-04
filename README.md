# MacOS builder setup scripts

The scripts in this folder are made to create a build environment for the MacOS Agent & create unsigned or signed builds of the MacOS Agent.

## Prerequisites

- A clean MacOS 10.13.6 (High Sierra) or higher host
- Varying environment variables & files present on the host (see individual files for specific requirements).

## Contents

- `builder_setup.sh`: installs all required build dependencies
- `build_script.sh`: does the omnibus build of the Agent.
- `notarization_script.sh` notarizes an Agent build. Will only work if the package was signed.
