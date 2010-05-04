require 'spec_helper'

require 'tempfile'

describe 'Basic operations:' do
  class Worker
    def write_to_file(file)
      file.write "success"
      file.close
    end
    def bad_exit
      exit 0
    end
  end
  
  attr_reader :proxy
  attr_reader :scheduler
  before(:each) do
    @scheduler = Procrastinate::Scheduler.new
    
    @proxy = scheduler.start(Worker)
  end

  describe "Worker writing to a temporary file (orderly shutdown)" do
    attr_reader :file
    before(:each) do
      @file = Tempfile.new('basic_op')
      proxy.write_to_file(file)
      
      scheduler.shutdown
    end
    
    it "should append 'success' to the file" do
      file.rewind
      file.read.should == 'success'
    end 
  end
  # describe "Worker that exits its process" do
  #   before(:each) do
  #     proxy.bad_exit
  #     scheduler.shutdown
  #   end
  #   
  #   it "should not have exited the scheduler (runs in its own process)" do
  #   end 
  # end
  
end