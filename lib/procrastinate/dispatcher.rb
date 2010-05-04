
class Procrastinate::Dispatcher
  # The class that needs to be instantiated and sent the work messages.
  attr_reader :worker_klass
  
  # The dispatcher runs in its own thread, which sleeps most of the time. 
  attr_reader :thread
  
  # This pipe is used to wait for events in the master process. 
  attr_reader :control_pipe
  
  # A hash of <pid, callback> that contains callbacks for all the child
  # processes we spawn. Once the process is complete, the callback is called
  # in the dispatcher/strategy's thread.
  attr_reader :handlers
  
  def initialize(strategy, worker_klass)
    @worker_klass = worker_klass
    @control_pipe = IO.pipe
    @strategy = strategy
    @handlers = {}
  end

  def self.start(strategy, worker_klass)
    new(strategy, worker_klass).tap do |dispatcher| 
      dispatcher.start
    end
  end
  def start
    register_signals
    start_thread
  end
  
  def register_signals
    trap('CHLD') { awaken_dispatcher }
  end
  
  def start_thread
    @thread = Thread.new do
      loop do
        wait_for_event
        reap_workers
        
        strategy.spawn_new_workers(self)
      end
    end
    
    thread.abort_on_exception = true
  end
  
  def wait_for_event
    # Returns array<ready_for_read, ..., ...>
    IO.select([control_pipe.first], nil, nil)

    # Consume the data (not important)
    control_pipe.first.read_nonblock(1024)
  rescue Errno::EAGAIN, Errno::EINTR
  end
  
  # Wake up the dispatcher thread. 
  #
  def wakeup
    control_pipe.last.write '.'
  end
  
  # Calls completion handlers for all the childs that have now exited.
  #     
  def reap_workers
    loop do
      child_pid, status = Process.waitpid2(-1, Process::WNOHANG)
      break unless child_pid

      # Trigger the completion callback
      handler = handlers.delete(child_pid)
      handler.call if handler
    end
  rescue Errno::ECHILD
    # Ignored: Child status has been reaped by someone else
  end
  
  # Spawns a process to work on +work_item+. If a block is given, it is called
  # when the task completes.
  #
  # Example: 
  # 
  #   spawn(wi) { puts "Task is complete" }
  #
  def spawn(work_item, &completion_handler)
    pid = fork do
      cleanup
      
      worker = worker_klass.new
      message, arguments, block = work_item
      worker.send(message, *arguments, &block)
      
      exit 0
    end
    
    handlers[pid] = completion_handler
  end
  
  # Gets executed in child process to clean up file handles and pipes that the
  # master holds. 
  #
  def cleanup
    # The child doesn't need the control pipe for now.
    control_pipe.each { |io| io.close }
  end

  def shutdown
    # TODO
  end
end
