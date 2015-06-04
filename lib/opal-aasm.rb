if RUBY_ENGINE == 'opal'
  require_relative 'opal/aasm/version.rb'
  require_relative 'opal/aasm.rb'
  require_relative 'opal-aasm.rb'
else
  require 'opal'
  require 'opal-jquery'
  require 'opal-react'
  Opal.use_gem 'aasm'
  Opal.use_gem 'react-source'
  Opal.append_path File.expand_path('..', __FILE__).untaint
end