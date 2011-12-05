require 'spec_helper'

describe "Block scheduling" do
  let(:scheduler) { Procrastinate::Scheduler.start }
  
  it "runs blocks in another process" do
    result = scheduler.schedule do
      Process.pid
    end
    
    result.value.should_not == Process.pid
  end 
end