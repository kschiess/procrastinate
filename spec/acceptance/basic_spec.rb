require 'spec_helper'

require 'tempfile'

describe 'Basic operations:' do
  class Worker
    def write_to_file(file)
      file.write "success"
      file.close
    end
    def bad_exit(file)
      file.write 'exit'
      exit 0
    end
  end
  
  attr_reader :proxy
  attr_reader :scheduler
  before(:each) do
    @scheduler = Procrastinate::Scheduler.start
    @proxy = scheduler.create_proxy(Worker.new)
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
  describe "Worker that exits its process" do
    let(:file) { Tempfile.new('basic_op') }
    
    def contents(file)
      file.rewind
      file.read
    end
    
    it "should not have exited the scheduler (runs in its own process)" do
      proxy.bad_exit(file)

      # Wait for the file to contain proof of process that exits
      timeout(2) do
        loop do
          break if contents(file) == 'exit'
        end
      end

      file.rewind
      proxy.write_to_file(file)
      scheduler.shutdown
      
      # We did successfully execute something after quitting a first process. 
      # That must mean that the scheduler continued to work.
      contents(file).should == 'success'
    end 
  end
end