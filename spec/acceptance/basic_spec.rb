require 'spec_helper'

describe 'Basic operations:' do
  class Worker
    def nop
      # print '.'
    end
    def write_to_file(file)
      # p :write_to_file
      file.write "success"
      file.close
    end
    def bad_exit(file)
      file.write 'exit'
      exit 0
    end
    def the_answer
      42
    end
  end
  
  let(:scheduler) { Procrastinate::Scheduler.start }
  let(:proxy)     { scheduler.create_proxy(Worker.new) }

  describe "Worker writing to a temporary file (orderly shutdown)" do
    let(:file) { Tempfile.new('basic_op') }
    before(:each) do
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
  describe "Worker doing nothing when started many times" do
    after(:each) { scheduler.shutdown }
    it "should not exhaust OS resources" do
      100.times do
        proxy.nop
      end
    end 
  end
  describe "Worker#the_answer return value" do
    subject { proxy.the_answer }
    after(:each) { scheduler.shutdown }
    
    its(:value) { should == 42 }
    context "after accessing value (blocking)" do
      before(:each) { subject.value }
      its(:ready?) { should == true }
    end
  end
end