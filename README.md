# Eppo Ruby SDK

[![Test and lint SDK](https://github.com/Eppo-exp/node-server-sdk/actions/workflows/lint-test-sdk.yml/badge.svg)](https://github.com/Eppo-exp/node-server-sdk/actions/workflows/lint-test-sdk.yml)

[Eppo](https://www.geteppo.com/) is a modular flagging and experimentation analysis tool. Eppo's Node SDK is built to make assignments in multi-user server side contexts, compatible with Ruby 3.0.6 and above. Before proceeding you'll need an Eppo account.

## Features

- Feature gates
- Kill switches
- Progressive rollouts
- A/B/n experiments
- Mutually exclusive experiments (Layers)
- Dynamic configuration

## Installation

```shell
gem install eppo-server-sdk
```

## Quick start

Begin by initializing a singleton instance of Eppo's client. Once initialized, the client can be used to make assignments anywhere in your app.

#### Initialize once

```ruby
require 'eppo_client'

config = EppoClient::Config.new('SDK-KEY-FROM-DASHBOARD')
client = EppoClient::init(config)
```


#### Assign anywhere

```ruby
require 'eppo_client'

client = EppoClient::Client.instance

variation = client.get_string_assignment(
  'new-user-onboarding', 
  user.id, 
  { country => user.country }, 
  'control'
)
```

## Assignment functions

Every Eppo flag has a return type that is set once on creation in the dashboard. Once a flag is created, assignments in code should be made using the corresponding typed function: 

```ruby
get_boolean_assignment(...)
get_numeric_assignment(...)
get_integer_assignment(...)
get_string_assignment(...)
get_json_assignment(...)
```

Each function has the same signature, but returns the type in the function name. For booleans use `getBooleanAssignment`, which has the following signature:

```ruby
getBoolAssignment: (
  flagKey: string,
  subjectKey: string,
  subjectAttributes: Record<string, any>,
  defaultValue: boolean,
) => boolean
  ```

## Assignment logger 

To use the Eppo SDK for experiments that require analysis, pass in a callback logging function to the `init` function on SDK initialization. The SDK invokes the callback to capture assignment data whenever a variation is assigned. The assignment data is needed in the warehouse to perform analysis.

The code below illustrates an example implementation of a logging callback using [Segment](https://segment.com/), but you can use any system you'd like. The only requirement is that the SDK receives a `logAssignment` callback function. Here we define an implementation of the Eppo `IAssignmentLogger` interface containing a single function named `logAssignment`:

```ruby
require 'segment/analytics'

# Connect to Segment (or your own event-tracking system)
Analytics = Segment::Analytics.new({ write_key: 'SEGMENT_WRITE_KEY' })

class CustomAssignmentLogger < EppoClient::AssignmentLogger
  def log_assignment(assignment)
    Analytics.track(assignment["subject"], "Eppo Assignment", assignment)
  end
end

config = EppoClient::Config.new(
  'SDK-KEY-FROM-DASHBOARD',
  assignment_logger: CustomAssignmentLogger.new
)
cli
```

## Philosophy

Eppo's SDKs are built for simplicity, speed and reliability. Flag configurations are compressed and distributed over a global CDN (Fastly), typically reaching your servers in under 15ms. Server SDKs continue polling Eppo’s API at 30-second intervals. Configurations are then cached locally, ensuring that each assignment is made instantly. Evaluation logic within each SDK consists of a few lines of simple numeric and string comparisons. The typed functions listed above are all developers need to understand, abstracting away the complexity of the Eppo's underlying (and expanding) feature set.

## SDK Development

In development, we recommend Docker: run `docker run --rm -v "$PWD":/usr/src/app -it $(docker build -q .) sh` from the root directory of this project and then the Rakefile commands can be run from the shell, e.g. `rake install` or `rake test`.
