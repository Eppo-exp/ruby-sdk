# frozen_string_literal: true

require_relative 'lib/eppo_client/version'

Gem::Specification.new do |s|
  s.name        = 'eppo-server-sdk'
  s.version     = EppoClient::VERSION
  s.summary     = 'Eppo SDK for Ruby'
  s.authors     = ['Eppo']
  s.email       = 'eppo-team@geteppo.com'
  s.files       = Dir.glob('lib/**/*.rb')
  s.homepage    = 'https://github.com/Eppo-exp/ruby-sdk'
  s.license     = 'MIT'
  s.add_dependency 'concurrent-ruby', '~> 1.1', '>= 1.1.9'
  s.add_dependency 'faraday', '~> 2.7', '>= 2.7.1'
  s.add_dependency 'faraday-retry', '~> 2.0', '>= 2.0.0'
  s.add_dependency 'semver2', '~> 3.4', '>= 3.4.2'
  s.add_development_dependency 'rake', '~> 13.0', '>= 13.0.6'
  s.add_development_dependency 'rspec', '~> 3.12', '>= 3.12.0'
  s.add_development_dependency 'rubocop', '~> 0.82.0'
  s.add_development_dependency 'webmock', '~> 3.18', '>= 3.18.1'
  s.required_ruby_version = '>= 3.0.6'
  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/Eppo-exp/ruby-sdk/issues',
    'documentation_uri' => 'https://docs.geteppo.com/feature-flags/sdks/server-sdks/ruby/',
    'homepage_uri' => 'https://geteppo.com/',
    'source_code_uri' => 'https://github.com/Eppo-exp/ruby-sdk',
    'wiki_uri' => 'https://github.com/Eppo-exp/ruby-sdk/wiki'
  }
end
