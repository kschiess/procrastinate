
require 'spec_helper'

describe Procrastinate::Scheduler do
  let(:scheduler) { Procrastinate::Scheduler.new(nil) }
  after(:each) { scheduler.shutdown }
  
  describe "<- #proxy" do
    class Worker
      def do_stuff
      end
    end
    
    context "return value" do
      attr_reader :return_value
      before(:each) do
        @return_value = scheduler.proxy(Worker.new)
      end

      it "should be a proxy for worker klass" do
        return_value.should respond_to(:do_stuff)
      end 
    end
  end
end