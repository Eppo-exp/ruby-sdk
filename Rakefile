# frozen_string_literal: true

require "rake/testtask"

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

task Rake::TestTask.new do |t|
  t.libs << 'test'
end
