
# Dispatches and handles tasks and task completion. Only low level unixy
# manipulation here, no strategy. The only methods you should call from the
# outside are #setup, #step, #wakeup and #shutdown. 
#
class Procrastinate::Dispatcher
  # This pipe is used to wait for events in the master process. 
  attr_reader :control_pipe
  
  # A hash of <pid, callback> that contains callbacks for all the child
  # processes we spawn. Once the process is complete, the callback is called
  # in the procrastinate thread.
  attr_reader :handlers
  
  def initialize
    @control_pipe = IO.pipe
    @handlers = {}
    @stop_requested = false
  end
  
  # Sets up resource usage for dispatcher. You must call this before dispatcher
  # can start its work. 
  #
  def setup
    register_signals
  end
  
  # Performs one step in the dispatchers work. This will sleep and wait
  # for work to be done, then wake up and reap processes that are still 
  # pending. This method will mostly sleep. 
  #
  def step
    # Sleep until either work arrives or we receive a SIGCHLD
    wait_for_event
    # Reap all processes that have terminated in the meantime.
    reap_childs
  end
  
  # Tears down the dispatcher. This frees resources that have been allocated
  # and waits for all children to terminate. 
  #
  def teardown
    wait_for_all_childs
    unregister_signals
  end
  
  # Wake up the dispatcher thread. 
  #
  def wakeup
    control_pipe.last.write '.'
  # rescue IOError
    # Ignore:
  end
  
  # Internal methods below this point. ---------------------------------------

  # Register signals that aid in child care. NB: Because we do this globally, 
  # holding more than one dispatcher in a process will not work yet. 
  #
  def register_signals
    trap('CHLD') { wakeup }
  end
  
  # Unregister signals. Process should be as before. 
  #
  def unregister_signals
    trap('CHLD', 'DEFAULT')
  end
    
  # Called from the child management thread, will put that thread to sleep 
  # until someone requests it to become active again. See #wakeup. 
  #
  def wait_for_event
    # Returns array<ready_for_read, ..., ...>
    IO.select([control_pipe.first], nil, nil)

    # Consume the data (not important)
    control_pipe.first.read_nonblock(1024)
  rescue Errno::EAGAIN, Errno::EINTR
  end
      
  # Calls completion handlers for all the childs that have now exited.
  #     
  def reap_childs
    loop do
      child_pid, status = Process.waitpid2(-1, Process::WNOHANG)
      break unless child_pid

      # Trigger the completion callback
      handler = handlers.delete(child_pid)
      handler.call(child_pid) if handler
    end
  rescue Errno::ECHILD
    # Ignore: This means that no childs remain. 
    unless handlers.empty?
      fail "Received ECHILD - no childs left, but some handlers remain uncalled!"
    end
  end
  
  # Spawns a process to work on +task+. If a block is given, it is called
  # when the task completes. This method should only be called from a strategy
  # inside the dispatchers thread. Otherwise it will expose threading issues. 
  #
  # Example: 
  # 
  #   spawn(wi) { |pid| puts "Task is complete" }
  #
  def create_process(task, &completion_handler)
    pid = fork do
      cleanup

      task.run

      exit! # this seems to be needed to avoid rspecs cleanup tasks
    end
    
    # The spawning is done in the same thread as the reaping is done. This is 
    # why no race condition to the following line exists. (or in other code, 
    # for that matter.)
    handlers[pid] = completion_handler
  end
  
  # Gets executed in child process to clean up file handles and pipes that the
  # master holds. 
  #
  def cleanup
    # Children dont need the parents signal handler
    unregister_signals
    
    # The child doesn't need the control pipe for now.
    control_pipe.each { |io| io.close }
  end

  # Waits for all childs to complete. 
  #
  def wait_for_all_childs
    # TODO Maybe signal KILL to children after some time. 
    until handlers.empty?
      wait_for_event
      reap_childs
    end
  end
end
