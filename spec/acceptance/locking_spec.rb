require 'spec_helper'

require 'tempfile'

describe "Scheduling 100 processes that fight for the same lock" do
  class LockingWorker
    attr_reader :runtime
    attr_reader :write_end
    def initialize(runtime, write_end)
      @runtime = runtime
      @write_end = write_end
    end
    
    def do
      runtime.lock('l1') do
        write_end.print 'l'
        sleep 0.00001 * rand(10)
        write_end.print 'u'
      end
    end
  end
  
  def tempdir
    t = Tempfile.new('procrastinate_lock_spec')
    path = t.path
    t.close(true)
    
    Dir.mkdir path
    path
  end

  before(:each) { Procrastinate::Lock.base = tempdir }
  after(:each) { FileUtils.rm_rf(Procrastinate::Lock.base) }
  
  
  # This pipe will be used to communicate from child processes to the parent.
  attr_reader :read_end, :write_end
  before(:each) do
    @read_end, @write_end = IO.pipe
  end
  
  # Starts the workers and waits for completion. 
  before(:each) do
    scheduler = Procrastinate::Scheduler.start
    runtime = scheduler.runtime
    worker = scheduler.create_proxy(LockingWorker.new(runtime, write_end))
    
    100.times do worker.do end
      
    scheduler.shutdown
    write_end.close
  end
  
  context "resulting lock acquisition sequence" do
    let(:sequence) {
      read_end.read_nonblock(200).each_char.map { |c| c=='l' ? :lock : :unlock }
    }
    
    it "should have 200 elements and no consecutive :lock -> :lock" do
      sequence.should have(200).elements
      sequence.each_cons(2).to_a.should_not include([:lock, :lock])
    end 
  end
end