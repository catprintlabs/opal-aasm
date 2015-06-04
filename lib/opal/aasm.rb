require "opal/aasm/version"
require "aasm"
require "aasm/persistence/plain_persistence"

module Opal
  module StateMachine
    
    # the following method adds the hidden react state variable to React::Component, by adding our 
    # own self.included method to React::Component.
    # Because we want to allow the modules to be required and included in any order extend_react_component
    # will be called twice.  Once when Opal::StateMachine is included, and once when this file is required.
    # The instance variable @original_included_method_for_state_machine protects us from infinite recursion.
    
    # 1 we are required first, we are included first     
    # 2 we are required first, we are included second    
    # 3 we are required second, we are included first
    # 4 we are required second, we are included second
    # 5 we are required, but they are not
    
    def self.extend_react_component(where, klass = nil)
      return if klass and klass.respond_to? :aasm_event_fired # case 4 already handled when we were required.
      if klass and klass.respond_to? :define_state
        # case 2
        klass.define_state :protected_current_react_state_var
        klass.define_method :aasm_event_fired do |event, from, to|
          protected_current_react_state_var! to.to_s if from != to
        end
      elsif defined? React::Component
        # case 3 + 4 (second call from include will be ignored)
        # case 1 (first call from require will be ignored)
        React::Component.module_eval do
          # alias_method does not work on :included so we do it the hard way
          unless @original_included_method_for_state_machine
            @original_included_method_for_state_machine = self.method(:included) 
            def self.included(base)
              @original_included_method_for_state_machine.call(base)
              base.define_state :protected_current_react_state_var
              base.define_method :aasm_event_fired do |event, from, to|
                protected_current_react_state_var! to.to_s if from != to
              end
            end
          end 
        end
      end
    end
    
    def current_state
      protected_current_react_state_var if respond_to? :render
      aasm.current_state.to_s
    end
    
    module AASMAPI
      
      # add the event and state methods to the class so we don't have to wrap with the aasm block

      ["event", "state"].each do |method_name|
        define_method(method_name)  do |*args, &block|
          aasm do
            send(method_name, *args, &block)
          end
        end
      end
      
      # add the state_machine_options directive and the new :state_name option

      def state_machine_options(opts={})
        define_method(opts.delete(:state_name)) do 
          protected_current_react_state_var if respond_to? :render
          aasm.current_state.to_s
        end if opts[:state_name]
        aasm opts
      end

    end
    
    def self.included(base)
      
      Opal::StateMachine.extend_react_component("StateMachine included", base)

      base.include AASM
      base.extend AASMAPI

    end

  end
end

# Work around a couple of incompatibilities with Opal and AASM

module AASM

  # redefine because of opal breaks when doing a super in this case
  def self.included(base)
    base.extend AASM::ClassMethods
    AASM::StateMachine[base] ||= AASM::StateMachine.new
    AASM::Persistence.load_persistence(base)  
    super rescue nil #<--------------------------------added because of bug in opal
  end

  module Persistence

    # override normal AASM load_persisentence method as it uses various features not supported by opal

    def self.load_persistence(base)
      base.send(:include, AASM::Persistence::PlainPersistence)
    end

  end

  # redefine the initialize method because it was was doing a very expensive
  # (for Opal) class_eval with a string (instead of a block).  While we are redefining this
  # the unnecessary options have been removed.

  class Base

    attr_reader :state_machine

    def initialize(klass, options={}, &block)
      @klass = klass
      @state_machine = AASM::StateMachine[@klass]
      @options = options

      # let's cry if the transition is invalid
      configure :whiny_transitions, true
      
    end
  end
end

Opal::StateMachine.extend_react_component("StateMachine file loaded")

# Last but not least add catch/throw to Opal as these are currently missing (as of version 8.beta)
# There is a PR to bring these into Opal properly.

class Object

  def catch(sym)
    yield
  rescue CatchThrow => e
    return e.arg if e.sym == sym
    raise e
  end

  def throw(*args)
    raise CatchThrow.new(args)
  end

  protected

  class CatchThrow < Exception 
    attr_reader :sym
    attr_reader :arg
    def initialize(args)
      @sym = args[0]
      @arg = args[1] if args.count > 1
    end
  end

end

