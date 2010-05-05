
# Dispatches and handles tasks and task completion. Only low level unixy
# manipulation here, no strategy. The only method you should call from the
# outside is #wakeup. 
#
class Procrastinate::Dispatcher
  # The dispatcher runs in its own thread, which sleeps most of the time. 
  attr_reader :thread
  
  # This pipe is used to wait for events in the master process. 
  attr_reader :control_pipe
  
  # A hash of <pid, callback> that contains callbacks for all the child
  # processes we spawn. Once the process is complete, the callback is called
  # in the dispatcher/strategy's thread.
  attr_reader :handlers
  
  # The strategy for dispatching new tasks. Makes all the decisions about
  # when to launch what process.
  #
  attr_reader :strategy
  
  def initialize(strategy)
    @strategy = strategy

    @control_pipe = IO.pipe
    @handlers = {}
    @stop_requested = false
  end

  def self.start(strategy)
    new(strategy).tap do |dispatcher| 
      dispatcher.start
    end
  end
  def start
    register_signals
    start_thread
  end
  
  # Called from anywhere, will complete all running tasks and stop the
  # dispatcher. 
  #
  def stop
    request_stop
    join
  end

  # Called from the dispatcher thread, will cause the dispatcher to wait on
  # all running tasks and then stop dispatching. 
  #
  def request_stop
    @stop_requested = true
    wakeup
  end
  
  def stop_requested?
    @stop_requested
  end
  
  def register_signals
    trap('CHLD') { wakeup }
  end
  
  def start_thread
    @thread = Thread.new do
      Thread.current.abort_on_exception = true
      
      # Loop until someone requests a shutdown.
      loop do
        wait_for_event
        reap_workers
        
        break if stop_requested?

        strategy.spawn_new_workers(self)
      end
      
      wait_for_all_childs
    end
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
  # rescue IOError
    # Ignore:
  end
  
  # Waits until the dispatcher completes its work. If you don't initiate a
  # shutdown, this may be forever.
  #
  def join
    @thread.join
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
  
  # Spawns a process to work on +task+. If a block is given, it is called
  # when the task completes.
  #
  # Example: 
  # 
  #   spawn(wi) { puts "Task is complete" }
  #
  def spawn(task, &completion_handler)
    pid = fork do
      cleanup

      task.run

      exit! # this seems to be needed to avoid rspecs cleanup tasks
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

  # Waits for all childs to complete. 
  #
  def wait_for_all_childs
    until handlers.empty?
      sleep 0.1
      reap_workers
    end
  end
end
