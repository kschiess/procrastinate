require 'spec_helper'

describe Procrastinate::DispatchStrategy::Throttled, 'limited to 2 tasks' do
  class Task
    def initialize
      @started = false
      @complete = false
      @notify = nil
    end
    def notify(block)
      @notify = block
    end
    def start;      @started = true; end
    def complete;   @complete = true and (@notify && @notify.call) if started?; end
    def complete?;  @complete end
    def started?;   @started; end
  end
  class StubDispatcher
    def spawn(task, &block)
      task.start
      task.notify(block)
    end
  end
  
  attr_reader :strategy
  attr_reader :dispatcher
  before(:each) do
    @strategy = Procrastinate::DispatchStrategy::Throttled.new(2)
    @dispatcher = StubDispatcher.new
  end
  
  context "when given 4 tasks to run" do
    attr_reader :initial
    attr_reader :others
    before(:each) do
      @initial = [Task.new, Task.new]
      @others = [Task.new, Task.new]
      
      (initial + others).each { |task| strategy.schedule(task) }
      
      # Allow the strategy to start workers
      strategy.spawn_new_workers(dispatcher)
    end
    
    it "should run only 2 tasks" do
      initial.each { |task| task.should be_started }
      others.each { |task| task.should_not be_started }
    end
    it "should run next tasks when completing old ones" do
      initial.each { |task| task.complete }

      # Allow the strategy to start workers
      strategy.spawn_new_workers(dispatcher)
      
      others.each { |task| task.should be_started }
    end 
  end
end