require 'spec_helper'

describe "Throttled strategy (:limit => 4) when given 8 tasks" do
  class Task < Struct.new(:log, :trigger)
    def run
      log.write('A')
      
      # Wait till we can read at least one byte from trigger
      loop do
        IO.select([trigger], nil, nil)  # wait for data to become available on trigger
        trigger.read_nonblock(1) and break rescue Errno::EAGAIN
      end
      
      log.write('B')
    end
  end
  attr_reader :log_read, :log_write
  attr_reader :trigger_write
  attr_reader :scheduler
  before(:each) do
    @scheduler = Procrastinate::Scheduler.start(
      Procrastinate::DispatchStrategy::Throttled.new(4)) 
      
    @log_read, @log_write = IO.pipe
    trigger_read, @trigger_write = IO.pipe

    # Schedule 8 tasks that all get the write end of the pipe. 
    task = scheduler.create_proxy(Task.new(log_write, trigger_read))
    8.times do
      task.run
    end
  end
  after(:each) do
    8.times { trigger_write.write '.' }
    scheduler.shutdown
  end
  
  # Counts the maximum number of concurrent tasks that have logged to the
  # pipe. 
  #
  def concurrent_tasks(pipe)
    concurrent = 0
    current = 0
    
    while IO.select([pipe], nil, nil, 0.1)
      case pipe.read_nonblock(1)
        when 'A' then current += 1
        when 'B'  then current -= 1
      end
      
      concurrent = [current, concurrent].max
    end
    
    concurrent
  end
  
  context "after letting all tasks finish" do
    before(:each) do
      # 8.times { trigger_write.write_nonblock '.' }
      # sleep 0.1
    end
    it "should never have had more than 4 simultaneous tasks" do
      concurrent_tasks(log_read).should <= 4
    end
  end
end