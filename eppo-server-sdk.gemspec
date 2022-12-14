# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'eppo-server-sdk'
  s.version     = '0.0.1'
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
    'lib/custom_errors.rb',
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
  s.add_dependency 'parse_gemspec', '~> 1.0', '>= 1.0.0'
  s.add_development_dependency 'rake', '~> 13.0', '>= 13.0.6'
  s.add_development_dependency 'rspec', '~> 3.12', '>= 3.12.0'
  s.add_development_dependency 'rubocop', '~> 1.41'
  s.add_development_dependency 'webmock', '~> 3.18', '>= 3.18.1'
  s.required_ruby_version = '>= 3.1.2'
  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/Eppo-exp/ruby-sdk/issues',
    'documentation_uri' => 'https://docs.geteppo.com/feature-flags/sdks/server-sdks/ruby/',
    'homepage_uri' => 'https://geteppo.com/',
    'source_code_uri' => 'https://github.com/Eppo-exp/ruby-sdk',
    'wiki_uri' => 'https://github.com/Eppo-exp/ruby-sdk/wiki'
  }
end
