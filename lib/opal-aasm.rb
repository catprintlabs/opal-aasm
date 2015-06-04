if RUBY_ENGINE == 'opal'
  require_relative 'opal/aasm/version.rb'
  require_relative 'opal/aasm.rb'
  require_relative 'opal-aasm.rb'
else
  require 'opal'
  Opal.use_gem 'aasm'
  Opal.append_path File.expand_path('..', __FILE__).untaint
end