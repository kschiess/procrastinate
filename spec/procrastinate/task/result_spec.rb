require 'spec_helper'

require 'procrastinate/task/result'

describe Procrastinate::Task::Result do
  let(:result) { described_class.new }
  
  context "when marked as failure" do
    before(:each) { result.process_died }
    
    it "is ready?" do
      result.should be_ready
    end 
    it "fails loudly if there is still an answer" do
      expect {
        result.incoming_message(:foo)
      }.to raise_error
    end 
    it "raises ChildDeath once #value is accessed" do
      expect {
        result.value
      }.to raise_error(Procrastinate::ChildDeath)
    end 
  end
  context "once it has received an answer" do
    before(:each) { result.incoming_message(:foo) }
    
    it "returns the answer in #value" do
      result.value.should == :foo
    end
    it "is ready?" do
      result.should be_ready
    end 
    it "fails when there is a second answer" do
      expect {
        result.incoming_message(:foo)
      }.to raise_error
    end 
  end
end