# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'parse_gemspec'

GEM_NAME = 'eppo-server-sdk'
GEM_VERSION = ParseGemspec::Specification.load('eppo-server-sdk.gemspec').to_hash_object[:version]

task default: :build

task :build do
  system "gem build #{GEM_NAME}.gemspec"
end

task install: :build do
  system "gem install #{GEM_NAME}-#{GEM_VERSION}.gem"
end

task devinstall: :build do
  system "gem install #{GEM_NAME}-#{GEM_VERSION}.gem --dev"
end

task publish: :build do
  system "gem push #{GEM_NAME}-#{GEM_VERSION}.gem"
end

task :clean do
  system 'rm *.gem'
end

test_data_dir = 'spec/test-data/'
file 'test-data' do
  rm_rf test_data_dir
  mkdir_p test_data_dir
  sh "gsutil cp gs://sdk-test-data/rac-experiments-v2.json #{test_data_dir}"
  sh "gsutil cp -r gs://sdk-test-data/assignment-v2 #{test_data_dir}"
end

RSpec::Core::RakeTask.new(:test) do |task|
  root_dir = Rake.application.original_dir
  task.pattern = "#{root_dir}/spec/*_spec.rb"
  task.verbose = false
end

task test: :devinstall
task test_refreshed_data: [:devinstall, 'test-data']
