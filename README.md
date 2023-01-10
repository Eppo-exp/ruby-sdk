# Eppo SDK for Ruby

## Getting Started

Refer to our [SDK documentation](https://docs.geteppo.com/feature-flags/sdks/server-sdks/ruby) for how to install and use the SDK.

## Supported Ruby Versions
This version of the SDK is compatible with Ruby 3.1.2 and above.

## Note for installation for SDK development

The Rakefile depends on pre-installing gems listed under `development_dependency` in the gemspec file. So install with gem commands first, which will install everything you need to run the tasks in the Rakefile, and then you will be able to run `rake install`, for example.

```
gem build eppo-server-sdk.gemspec
gem install eppo-server-sdk-<version_number>.gem --dev
```