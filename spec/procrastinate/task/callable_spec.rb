require 'spec_helper'

describe Procrastinate::Task::Callable do
  let(:endpoint) { flexmock(:endpoint).tap { |m| 
    m.should_receive(:send).by_default } 
  }
  it "should call the block in run" do
    endpoint.should_receive(:send).with(:result).once
    
    block = flexmock(:callable, :call => :result)
    callable = described_class.new(block)
    
    callable.run(endpoint)
  end 
end