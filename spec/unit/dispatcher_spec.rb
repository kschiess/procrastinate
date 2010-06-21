require 'spec_helper'

require 'thread'

describe Procrastinate::Dispatcher do
  describe "with a simple strategy" do
    attr_reader :strategy
    attr_reader :dispatcher
    before(:each) do
      # Strategy stubs
      @strategy = flexmock(:strategy)
      strategy.should_receive(:spawn_new_workers).by_default
      
      @dispatcher = Procrastinate::Dispatcher.start(strategy)
    end
    
    context "after stopping the dispatcher" do
      before(:each) { dispatcher.stop }
      
      it "should stop the thread when all running tasks complete" do
        dispatcher.thread.should_not be_alive
      end 
      it "should unregister signals: CHLD" do
        # If no signal handler is installed, the trap method returns nil
        trap('CHLD', 'DEFAULT').should be_nil
      end 
    end
    
    context "that expects completion to be called" do
      before(:each) do
        @completed = false
                
        strategy.should_receive(:spawn_new_workers).and_return do |spawner|
          spawner.spawn(flexmock(:task, :run => nil)) { @completed = true }
        end
      end
      after(:each) do
        dispatcher.stop
      end

      it "should start the task and call its callback" do
        timeout(1) do
          dispatcher.wakeup
          sleep 0.01 until @completed
        end
      end
    end
  end
end