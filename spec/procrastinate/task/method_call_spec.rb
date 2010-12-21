require 'spec_helper'

describe Procrastinate::Task::MethodCall do
  let(:endpoint) { flexmock(:endpoint).tap { |m| 
    m.should_receive(:send).by_default } 
  }
  let(:instance) { flexmock(:instance) }
  it "should call the given method in #run" do
    instance.should_receive(:foo).with(:bar).once
    
    Procrastinate::Task::MethodCall.new(instance, 
      :foo, [:bar], nil
    ).run(endpoint)
  end 
end