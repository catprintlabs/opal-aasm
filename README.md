# Acts-As-State-Machine for Opal

Allows the [Acts As State Machine (aasm)](https://github.com/aasm/aasm) gem to be used with the [Opal Ruby Transpiler](http://opalrb.org/).  Its also ready to work right along side [react.rb](https://github.com/zetachang/react.rb) UI components.  For detailed documentation on Acts As State Machine, refer the to [AASM](https://github.com/aasm/aasm) github page.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'opal-aasm'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install opal-aasm

## Usage

```ruby
class StateMachine
  
  include Opal::StateMachine
  
  state_machine_options :state_name => :component_state, :whiny_transitions => true
  
  state :cleaning
  state :sleeping, :initial => true
  state :running

  event(:run, after: -> () {puts "started running!!!!!!"}) do
    transitions :from => :sleeping, :to => :running
  end

  event(:clean, error: -> () {puts "don't clean now!!!!!!!"}) do
    transitions :from => :running, :to => :cleaning
  end

  event :sleep do
    transitions :from => [:running, :cleaning], :to => :sleeping
  end
  
  # AASM will automatically define methods may_run?, run!, may_sleep?, sleep! etc
  
  # to access these from the javascript console you would type 
  # machine = Opal.StateMachine.$new()
  # machine["$may_run?"]()
  # machine["$run"]()
  # machine["$component_state"]()

end
```

Note that you do not need to wrap the state and event directives with the normal `aasm do ... end`, but you 
may still do so if desired. If you have a name conflict with `state` or `event` simply do the include of Opal::StateMachine after you define your state or event methods, and use the normal `aasm` dsl wrapper.

To send options to AASM use the `state_machine_options` directive as shown above.

Opal-aasm will define a method called `current_state` that can be used to get the current state.  You may override
the method name by using the `state_name` option in the `state_machine_options` directive as shown above. 

## Using with [React.rb](https://github.com/zetachang/react.rb) 

The opal-aasm gem is "React" aware.  Adding a state machine to a react component gives a very easy and powerful way to manage component state.   For example consider turning the above into a react component:

```ruby
class StateMachine
  
  include React::Component
  
  def render
    div do
      span { "current state: #{component_state}"}
      button {"run"  }.on(:click) {run!}   if may_run?
      button {"sleep"}.on(:click) {sleep!} if may_sleep?
      button {"clean"}.on(:click) {clean!} # we will check this in the state call back 
      button {"secret clean"}.on(:click) {clean; alert("notice that the current state did not change!")}
    end
  end
  
end
```

When both `React::Component` and `Opal::StateMachine` are included in the same class a hidden react state is updated whenever there is a state transition.  The rest is handled by the magic of React.

AASM creates two methods for each event, for example `clean` and `clean!`.  Normally you will use the `clean!` method as this updates the underlying `React::Component` state.  For example `clean` is used on the last button in the example, and
because of this the value of component_state will not change, and so the component will not be re-rendered by react. 

## Summary of additional features 

The opal-aasm gem is intended to be upwards compatible with the standard AASM.  The following are the additional features added by opal-aasm.

* No need to wrap `state` and `event` directives in an aasm block.
* AASM options may be provided using the `state_machine_options` directive.
* The `current_state` method may be used to access the current state.  The name can be changed using the `state_name` option.
* Will persist the current state as a react state variable if the `React::Component` mixin is present in the same class.
* Use of the plain or bang! event methods will determine if the react state will be updated. 

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/catprintlabs/opal-aasm. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

