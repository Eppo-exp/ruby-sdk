# Eppo SDK for Ruby

This repository has been migrated to https://github.com/Eppo-exp/eppo-multiplatform.

## Getting Started

Refer to our [SDK documentation](https://docs.geteppo.com/feature-flags/sdks/ruby) for how to install and use the SDK.

## Supported Ruby Versions
This version of the SDK is compatible with Ruby 3.0.6 and above.

## Note for installation for SDK development

We recommend developing in Docker: run `docker run --rm -v "$PWD":/usr/src/app -it $(docker build -q .) sh` from the root directory of this project and then the Rakefile commands can be run from the shell, e.g. `rake install` or `rake test`.
