
require 'thread'

# API Frontend for the procrastinate library. Allows scheduling of tasks and
# workers in seperate processes and provides minimal locking primitives. 
# 
# == Synopsis
#   scheduler = Procrastinate::Scheduler.start
#   
# Schedule a block to run in its own process:
#   result = scheduler.schedule { Process.pid }
#   result.value  # => child process pid
#
# Or schedule a message call to an object to be run in another process: 
#   proxy = scheduler.proxy(1)
#   result = proxy + 2
#   result.value  # => 3
#   
# You can ask the result value if it is ready yet: 
#   result.ready? # true/false
#
# Stop the scheduler, waiting for all scheduled work to finish:
#   scheduler.shutdown 
# 
# Or shutting down hard, doesn't wait for work to finish: 
#   scheduler.shutting(true)
#
# @note Each scheduler owns its own thread that does all the processing. The
#   interface between your main thread and the procrastinate thread is defined
#   in this class.
#
class Procrastinate::Scheduler
  # Process manager associated with this scheduler
  attr_reader :manager
  # Schedule strategy associated with this scheduler
  attr_reader :strategy
  # Task queue
  attr_reader :task_producer
    
  # @see Scheduler.start
  def initialize(strategy)
    @strategy   = strategy || Procrastinate::SpawnStrategy::Default.new
    @manager = Procrastinate::ProcessManager.new

    # State takes three values: :running, :soft_shutdown, :real_shutdown
    # :soft_shutdown will not accept any new tasks and wait for completion
    # :real_shutdown will stop as soon as possible (still closing down nicely)
    @state          = :running
    
    # If we're used in server mode, this will be replaced with a task producer
    # that produces new worker processes.
    @task_producer  = Queue.new
  end
  
  # Starts a new scheduler.
  # 
  # @param strategy [SpawnStrategy] strategy to use when spawning new processes.
  #   Will default to {SpawnStrategy::Default}.
  # @return [Scheduler]
  #
  def self.start(strategy=nil)
    new(strategy).
      tap { |obj| obj.start }
  end
  def start
    start_thread
  end
  
  # Returns a proxy for the +worker+ instance that will allow executing its
  # methods in a new process. 
  #
  # @example
  #   proxy = scheduler.proxy(worker)
  #   status = proxy.do_some_work    # will execute later and in its own process
  #
  # @param worker [Object] Ruby object that executes the work
  # @return [Proxy]
  #
  def proxy(worker)
    return Procrastinate::Proxy.new(worker, self)
  end
  
  # Returns a runtime linked to this scheduler. This method should only be
  # used inside task execution processes; If you call it from your main 
  # process, the result is undefined.
  #
  # @return [Runtime]
  #
  def runtime
    Procrastinate::Runtime.new
  end
    
  # Called by the proxy to schedule work. You can implement your own Task
  # classes; the relevant interface consists of only a #run method. 
  #
  # @overload schedule(task=nil)
  #   Runs task in its own worker process.
  #   @param task [#run] task to be run in its own worker process
  #   @return [Task::Result]
  #
  # @overload schedule(&block)
  #   Executes the Ruby block in its own worker process.
  #   @param block [Proc] block to be executed in worker process
  #   @return [Task::Result]
  #
  def schedule(task=nil, &block)
    fail "Shutting down..." if @state != :running
    
    fail ArgumentError, "Either task or block must be given." \
      if !task && !block
    
    if block
      task = Procrastinate::Task::Callable.new(block)
    end
    
    task_producer << task
    
    # Create an occasion for spawning
    manager.wakeup
    
    task.result
  end
  
  # Waits for the currently queued work to complete. This can be used at the
  # end of short scripts to ensure that all work is done. 
  #
  def join
    @state = :soft_shutdown
    
    # NOTE: Currently, this method busy-loops until all childs terminate. 
    # This is not as elegant as I whish it to be, but its a start. 
    
    # Wait until all tasks are done.
    loop do
      manager.wakeup
      break if task_producer.empty? && manager.process_count==0
      sleep 0.01
    end
    
  ensure
    @state = :running
  end
  
  # Immediately shuts down the procrastinate thread and frees resources. 
  # If there are any tasks left in the queue, they will NOT be executed. 
  #
  def shutdown(hard=false)
    join unless hard

    # Set the flag that will provoke shutdown
    @state = :real_shutdown
    # Wake the manager up, making it check the flag
    manager.wakeup
    # Wait for the manager to finish its work. This waits for child processes
    # and then reaps their result, avoiding zombies. 
    @thread.join if @thread
  end
  
private
  # Spawns new tasks (if needed). 
  #   *control thread* 
  #
  def spawn
    while strategy.should_spawn? && !task_producer.empty?
      task = task_producer.pop
      strategy.notify_spawn
      manager.create_process(task) do
        strategy.notify_dead
      end
    end
  end
  
  # This is the content of the control thread that is spawned with
  # #start_thread
  #   *control thread* 
  #
  def run
    # Start managers work
    manager.setup

    # Loop until someone requests a shutdown.
    loop do
      manager.step

      break if @state == :real_shutdown
      spawn
    end

    manager.teardown
  rescue => ex
    # Sometimes exceptions vanish silently. This will avoid that, even though
    # they should abort the whole process.
    
    warn "Exception #{ex.inspect} caught."
    ex.backtrace.first(5).each do |line|
      warn line
    end
    
    raise
  end

  # Hosts the control thread that runs in parallel with your code. This thread
  # handles child spawning and reaping. 
  #
  def start_thread # :nodoc: 
    Thread.abort_on_exception = true
    
    @thread = Thread.new do
      run
    end
  end
end