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
    
    context "when lock has been acquired" do
      before(:each) { subject.acquire }
      
      # Spawns a subprocess that tries to #acquire 'l1'. 
      #
      def acquire_in_subprocess?(name)
        r, w = IO.pipe
        fork do
          l1 = Procrastinate::Lock.new('l1')
          begin
            timeout(0.01) do
              l1.acquire
              w.write 's'
            end
          rescue 
            w.write 'f'
          end
          exit 0
        end
        Process.wait2

        IO.select([r])
        r.read_nonblock(1) == 's'
      end
      
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
  end
end