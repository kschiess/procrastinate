require 'spec_helper'

require 'thread'

describe Procrastinate::ProcessManager do
  let(:manager) { subject }
  before(:each) { manager.setup }
  after(:each) { manager.teardown }
  
  its(:process_count) { should == 0}
  
  # context "when one process is running" do
  #   class Task 
  #     def run(endpoint)
  #       
  #     end
  #   end
  #   before(:each) { subject.create_process() }
  # end
end