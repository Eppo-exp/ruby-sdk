# frozen_string_literal: true

require 'rspec/core/rake_task'

GEM_NAME = 'eppo_client'
GEM_VERSION = '0.0.0'

task default: :build

task :build do
  system "gem build #{GEM_NAME}.gemspec"
end

task install: :build do
  system "gem install #{GEM_NAME}-#{GEM_VERSION}.gem"
end

task publish: :build do
  system "gem push #{GEM_NAME}-#{GEM_VERSION}.gem"
end

task :clean do
  system 'rm *.gem'
end

test_data_dir = 'test/test-data/'
file 'test-data' do
  rm_rf test_data_dir
  mkdir test_data_dir
  sh "gsutil cp gs://sdk-test-data/rac-experiments-v2.json #{test_data_dir}"
  sh "gsutil cp -r gs://sdk-test-data/assignment-v2 #{test_data_dir}"
end

task :test_data do
  system 'rm *.gem'
end

RSpec::Core::RakeTask.new(:test) do |task|
  root_dir = Rake.application.original_dir
  task.pattern = "#{root_dir}/spec/*_spec.rb"
  task.verbose = false
end
