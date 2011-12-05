require 'spec_helper'

describe "Implicit usage / when not starting Procrastinate by hand" do
  # Spec isolation
  before(:each) { Procrastinate.reset }
  
  class Worker
    def doit
      rand(100)
    end
  end
  let(:proxy) { Procrastinate.proxy(Worker.new) }

  describe "Procrastinate.join" do
    let(:results) { 10.times.map { proxy.doit } }
    before(:each) { results # trigger 
    }
    
    before(:each) { Procrastinate.join }
    it "should wait for all tasks to complete" do
      results.count { |r| r.ready? }.should == 10
    end 
  end
end