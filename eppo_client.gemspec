# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'eppo_client'
  s.version     = '0.0.0'
  s.summary     = 'Eppo SDK for Ruby'
  s.authors     = ['Eppo']
  s.email       = 'eppo-team@geteppo.com'
  s.files       = [
    'lib/assignment_logger.rb',
    'lib/client.rb',
    'lib/config.rb',
    'lib/configuration_requestor.rb',
    'lib/configuration_store.rb',
    'lib/constants.rb',
    'lib/eppo_client.rb',
    'lib/http_client.rb',
    'lib/lru_cache.rb',
    'lib/poller.rb',
    'lib/rules.rb',
    'lib/shard.rb',
    'lib/validation.rb'
  ]
  s.homepage    = 'https://github.com/Eppo-exp/ruby-sdk'
  s.license     = 'MIT'
  s.add_dependency 'concurrent-ruby', '~> 1.1', '>= 1.1.9'
  s.add_dependency 'faraday', '~> 2.7', '>= 2.7.1'
  s.add_dependency 'faraday-retry', '~> 2.0', '>= 2.0.0'
  s.required_ruby_version = '>=3.1.2'
end