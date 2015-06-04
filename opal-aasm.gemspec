# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opal/aasm/version'

Gem::Specification.new do |spec|
  spec.name          = "opal-aasm"
  spec.version       = Opal::StateMachine::VERSION
  spec.authors       = ["Mitch VanDuyn"]
  spec.email         = ["mitch@catprint.com"]

  spec.summary       = "Acts-As-State-Machine for Opal"
  spec.description   = <<DESCRIPTION
Allows the Acts As State Machine (aasm) gem to be used with the Opal Ruby Transpiler.
Its also ready to work right along side react.rb UI components.  For detailed documentation on Acts As State Machine, 
refer the to AASM github page at https://github.com/aasm/aasm.
DESCRIPTION
  spec.homepage      = "https://github.com/catprintlabs/opal-aasm"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "opal-rspec"
  spec.add_development_dependency "opal-jquery"
  spec.add_development_dependency 'react-source', '~> 0.12'
  spec.add_development_dependency 'opal-react'
  spec.add_runtime_dependency 'opal'
  spec.add_runtime_dependency 'aasm'
  
end
