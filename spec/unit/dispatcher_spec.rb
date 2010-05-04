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
      
      # Worker class expectation
      worker_klass = Class.new
      worker_klass.instance_eval do
        define_method(:message) { |a,b,c| puts "holler from #{Process.pid}" }
      end
      
      @dispatcher = Procrastinate::Dispatcher.start(strategy, worker_klass)
    end
    
    it "should stop the thread when all running tasks complete" do
      dispatcher.stop
      
      dispatcher.thread.should_not be_alive
    end 
    context "that expects completion to be called" do
      before(:each) do
        button = flexmock().should_receive(:push).once.mock
        strategy.should_receive(:spawn_new_workers).and_return do |spawner|
          spawner.spawn([:message, [1,2,3], nil]) { button.push }
        end
      end

      it "should start the task and call its callback" do
        dispatcher.wakeup
        dispatcher.stop
      end
    end
  end
end