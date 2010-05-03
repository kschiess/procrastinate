require 'spec_helper'

require 'tempfile'

describe 'Basic operations' do
  
  class Worker
    def write_to_file(file)
      file.write "success"
    end
  end
  
  attr_reader :proxy
  attr_reader :scheduler
  before(:each) do
    @scheduler = Procrastinate::Scheduler.new
    
    @proxy = scheduler.start(Worker)
  end

  describe "worker writing to a temporary file" do
    attr_reader :file
    before(:each) do
      @file = Tempfile.new('basic_op')
      file.unlink

      proxy.write_to_file(file)
    end
    
    it "should append 'success' to the file" do
      file.rewind
      file.read.should == 'success'
    end 
  end
end