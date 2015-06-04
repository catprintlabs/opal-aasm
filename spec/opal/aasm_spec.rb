require 'spec_helper'

class StateMachine
  
  include Opal::StateMachine
  
  state :cleaning
  state :sleeping, :initial => true
  state :running

  event(:run) do
    transitions :from => :sleeping, :to => :running
  end

  event(:clean) do
    transitions :from => :running, :to => :cleaning
  end

  event :sleep do
    transitions :from => [:running, :cleaning], :to => :sleeping
  end

end

class StateMachine2 < StateMachine
  state_machine_options state_name: :component_state
end

class QuietMachine
  include Opal::StateMachine
  state_machine_options :whiny_transitions => false
  state :s1
  event(:e) 
end
  
  

describe Opal::StateMachine do

  it 'has a version number' do
    expect(Opal::StateMachine::VERSION).not_to be nil
  end

  it 'has a current_state method' do
    expect(StateMachine.new.current_state).to eq('sleeping')
  end

  it 'can use a different method name for the current state' do
    expect(StateMachine2.new.component_state).to eq('sleeping')
  end
  
  it "defines events" do
    state_machine = StateMachine.new
    state_machine.run
    expect(state_machine.current_state).to eq("running")
  end
  
  it "defines may_... methods" do
    expect(StateMachine.new.may_clean?).to be_falsy
  end
  
  it "is whiny by default" do
    expect{StateMachine.new.clean}.to raise_error(AASM::InvalidTransition)
  end
  
  it "can send other options such as :whiny_transitions to AASM" do
    expect{QuietMachine.new.e}.not_to raise_error
  end
  
  
end
