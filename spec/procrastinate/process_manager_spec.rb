require 'spec_helper'

require 'thread'

describe Procrastinate::ProcessManager do
  let(:manager) { subject }
  before(:each) { manager.setup }
  after(:each) { manager.teardown }
  
  its(:process_count) { should == 0}
  
  describe '#wait_for_all_childs' do
    describe 'with a fake child' do
      let(:child) { Procrastinate::ProcessManager::ChildProcess.new(nil, nil) }
      before(:each) { manager.children[1234] = child }
      
      it "regression: correctly cleans up children" do
        child.start
        child.sigchld_received
        
        manager.wakeup
        manager.teardown
      end 
    end
  end
end