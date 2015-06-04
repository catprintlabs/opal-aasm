#require "opal/aasm/version"
require "aasm"

# add the hidden react state variable to React::Component
module React
  module Component

    # alias_method does not work on :included so we do it the hard way
    @original_included_method_for_state_machine = self.method(:included) rescue nil 

    def self.included(base)

      @original_included_method_for_state_machine.call(base) rescue nil

      base.class_eval do 

        # define the hidden state variable
        define_state :protected_current_react_state_var

      end
    end 
  end
end

module Opal
  module StateMachine
    
    def current_state
      aasm.current_state
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
          aasm.current_state
        end if opts[:state_name]
        aasm opts
      end

    end

    def self.included(base) 

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
      base.send(:include, AASM::Persistence::ReactPersistence)
    end
    
    # the ReactPersistance module is just the basic AASM plain persistance module but with read and write throughs
    # to the hidden React state variable.  Instead of rescues we should probably intelligently check the aasm
    # options

    module ReactPersistence

      def aasm_read_state
        protected_current_react_state_var rescue nil # reading informs react system that we care about this variable
        current = aasm.instance_variable_get("@current_state")
        return current if current
        aasm.instance_variable_set("@current_state", aasm.enter_initial_state)
      end

      def aasm_write_state(new_state)
        protected_current_react_state_var! new_state.to_s if new_state.to_s != protected_current_react_state_var rescue nil
        true
      end

      def aasm_write_state_without_persistence(new_state)
        true
      end

    end

  end

  # redefine the initialize method because it was was doing a very expensive
  # (for Opal) class_eval with a string (instead of a block)

  class Base

    attr_reader :state_machine

    def initialize(klass, options={}, &block)
      @klass = klass
      @state_machine = AASM::StateMachine[@klass]
      @state_machine.config.column ||= (options[:column] || :aasm_state).to_sym # aasm4
      # @state_machine.config.column = options[:column].to_sym if options[:column] # master
      @options = options

      # let's cry if the transition is invalid
      configure :whiny_transitions, true

      # create named scopes for each state
      configure :create_scopes, true

      # don't store any new state if the model is invalid (in ActiveRecord)
      configure :skip_validation_on_save, false

      # use requires_new for nested transactions (in ActiveRecord)
      configure :requires_new_transaction, true

      # set to true to forbid direct assignment of aasm_state column (in ActiveRecord)
      configure :no_direct_assignment, false

      configure :enum, nil

      return

      # original released version has the following, which would require the whole opal-parser be 
      # loaded.  Its irrelevant so we are skipping.  Need a PR for AASM to change this to a 
      # block instead of string.

      @klass.class_eval %Q(
        def #{@state_machine.config.column}=(state_name)
          if self.class.aasm.state_machine.config.no_direct_assignment
            raise AASM::NoDirectAssignmentError.new(
              'direct assignment of AASM column has been disabled (see AASM configuration for this class)'
            )
          else
            super
          end
        end
      )
    end
  end
end

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
