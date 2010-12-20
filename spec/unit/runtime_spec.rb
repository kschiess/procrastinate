require 'spec_helper'

describe Procrastinate::Runtime do
  let(:runtime) { Procrastinate::Runtime.new }
  describe "<- #lock(name)" do
    it "should delegate to Procrastinate::Lock#lock" do
      lock = flexmock(:lock)
      flexmock(Procrastinate::Lock).
        should_receive(:new => lock)
      
      lock.should_receive(:lock).once.and_yield
      
      lock.lock('test') { }
    end 
  end
end