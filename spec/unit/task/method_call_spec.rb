require 'spec_helper'

describe Procrastinate::Task::MethodCall do
  it "should call the given method in #run" do
    klass = flexmock(Class.new).
      new_instances { |i| i.should_receive(:foo).with(:bar).once }.mock
      
    Procrastinate::Task::MethodCall.new(klass, 
      :foo, [:bar], nil
    ).run
  end 
end