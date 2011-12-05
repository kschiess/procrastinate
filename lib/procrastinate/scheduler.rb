
require 'thread'

# API Frontend for the procrastinate library. Allows scheduling of tasks and
# workers in seperate processes and provides minimal locking primitives. 
#
# Each scheduler owns its own thread that does all the processing. The
# interface between your main thread and the procrastinate thread is defined
# in this class.
#
class Procrastinate::Scheduler
  attr_reader :manager
  attr_reader :strategy
  attr_reader :task_queue
    
  def initialize(strategy)
    @strategy   = strategy || Procrastinate::SpawnStrategy::Default.new
    @manager = Procrastinate::ProcessManager.new

    # State takes three values: :running, :soft_shutdown, :real_shutdown
    # :soft_shutdown will not accept any new tasks and wait for completion
    # :real_shutdown will stop as soon as possible (still closing down nicely)
    @state      = :running
    @task_queue = Queue.new
  end
  
  # Starts a new scheduler
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
  # Example: 
  #
  #   proxy = scheduler.proxy(worker)
  #   status = proxy.do_some_work    # will execute later and in its own process
  #
  def proxy(worker)
    return Procrastinate::Proxy.new(worker, self)
  end
  
  # Returns a runtime linked to this scheduler. This method should only be
  # used inside task execution processes; If you call it from your main 
  # process, the result is undefined.
  #
  def runtime
    Procrastinate::Runtime.new
  end
    
  # Called by the proxy to schedule work. You can implement your own Task
  # classes; the relevant interface consists of only a #run method. 
  #
  def schedule(task=nil, &block)
    fail "Shutting down..." if @state != :running
    
    fail ArgumentError, "Either task or block must be given." \
      if !task && !block
    
    if block
      task = Procrastinate::Task::Callable.new(block)
    end
    
    task_queue << task
    
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
      break if task_queue.empty? && manager.process_count==0
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
    @thread.join
  end
  
private
  # Spawns new tasks (if needed). 
  #   *control thread* 
  #
  def spawn
    while strategy.should_spawn? && !task_queue.empty?
      task = task_queue.pop
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