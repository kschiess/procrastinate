
require 'spec_helper'

describe Procrastinate::Proxy do
  class Worker
    def do_work(*args)
    end
  end
  
  attr_reader :proxy
  attr_reader :klass
  attr_reader :scheduler
  before(:each) do
    @scheduler = flexmock(:scheduler)
    @proxy = Procrastinate::Proxy.new(Worker.new, scheduler)
  end
  
  describe "<- #respond_to?" do
    it "should return true for :do_work" do
      proxy.should respond_to(:do_work)
    end
    it "should return false for :foobar" do
      proxy.should_not respond_to(:foobar)
    end 
  end
  describe "missing method" do
    before(:each) { scheduler.should_receive(:schedule).by_default }

    it "should enqueue work" do
      scheduler.
        should_receive(:schedule).
        with(Procrastinate::Task::Callable).
        once
      
      proxy.do_work(1,2,3)
    end 
    it "should return a status object" do
      proxy.do_work(1).should_not be_nil
    end
  end
end