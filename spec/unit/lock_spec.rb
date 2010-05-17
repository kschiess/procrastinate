require 'spec_helper'

require 'tempfile'

describe Procrastinate::Lock do
  def tempdir
    t = Tempfile.new('procrastinate_lock_spec')
    path = t.path
    t.close(true)
    
    Dir.mkdir path
    path
  end

  before(:each) { Procrastinate::Lock.base = tempdir }
  after(:each) { FileUtils.rm_rf(Procrastinate::Lock.base) }
  
  context "instance 'l1'" do
    subject { Procrastinate::Lock.new('l1') }
    
    its(:name) { should == 'l1' }
    its(:file) { should_not be_nil }
    
    # Spawns a subprocess that tries to #acquire 'l1'. 
    #
    def acquire_in_subprocess?(name)
      r, w = IO.pipe
      fork do
        r.close
        l1 = Procrastinate::Lock.new('l1')
        begin
          timeout(0.01) do
            l1.acquire
            w.write 's'
          end
        rescue Timeout::Error
          w.write 'f'
        end
        exit 0
      end
      Process.wait2

      IO.select([r], nil, nil, 1)
      r.read_nonblock(1) == 's'
    end
    
    context "when lock has been acquired" do
      before(:each) { subject.acquire }
      
      it "should allow acquire multiple times" do
        timeout(1) { subject.acquire }
      end 
      it "should not allow a subprocess to acquire it" do
        acquire_in_subprocess?('l1').should == false
      end
      
      context "and released" do
        before(:each) { subject.release }
        
        it "should allow release multiple times" do
          subject.release
        end
        it "should allow a subprocess to acquire the lock" do
          acquire_in_subprocess?('l1').should == true
        end 
      end
    end
    describe "<- #synchronize" do
      it "should not allow reacquire from another process" do
        subject.synchronize do
          acquire_in_subprocess?('l1').should == false
        end
        acquire_in_subprocess?('l1').should == true
      end 
    end
  end
end