#require "bundler/gem_tasks"
#require "rspec/core/rake_task"

#RSpec::Core::RakeTask.new(:spec)

#task :default => :spec
# Rakefile
require 'opal/rspec/rake_task'
require 'bundler'
Bundler.require

# Add our opal/ directory to the load path
Opal.append_path File.expand_path('../lib', __FILE__)


Opal::RSpec::RakeTask.new(:default)