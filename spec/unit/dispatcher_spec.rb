require 'spec_helper'

require 'thread'

describe Procrastinate::Dispatcher do
  attr_reader :queue, :worker_klass
  before(:each) do
    @queue = Queue.new
  end
  
  describe ".start" do
    it "should return a Dispatcher" do
      Procrastinate::Dispatcher.
        start(queue, worker_klass).
        should be_an_instance_of(Procrastinate::Dispatcher)
    end
  end
  describe "<- #join" do
    
  end
  describe "<- #request_shutdown" do
    
  end
end