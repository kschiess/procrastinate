
require 'state_machine'
require 'cod'

# Dispatches and handles tasks and task completion. Only low level unixy
# manipulation here, no strategy. The only methods you should call from the
# outside are #setup, #step, #wakeup and #shutdown. 
#
class Procrastinate::ProcessManager
  autoload :ChildProcess,   'procrastinate/process_manager/child_process'
  
  # This pipe is used to wait for events in the master process. 
  attr_reader :control_pipe
  
  # A hash of <pid, callback> that contains callbacks for all the child
  # processes we spawn. Once the process is complete, the callback is called
  # in the procrastinate thread.
  attr_reader :children
      
  def initialize
    # This controls process manager wakeup
    @control_pipe = IO.pipe
    
    # All presently running children
    @children = {}

    # Master should read from @master, Children write to @child
    @master, @child = Cod.pipe.split
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
  
  # Returns the number of child processes that are alive at this point. Note
  # that even if a child process is marked dead internally, it counts towards
  # this number, since its results may not have been dispatched yet. 
  # 
  def process_count
    children.count
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
  # This method also depletes the child queue, reading end of processing
  # messages from all childs and dispatching them to the children. 
  #
  def wait_for_event
    cp_read_end = control_pipe.first
    
    loop do # until we have input in the cp_read_end (control_pipe)
      # TODO Why does procrastinate (cod) hang sometimes when there is no
      # timeout here? What messages are we missing?
      ready = Cod.select(1, 
        :child_msgs => @master, :control_pipe => cp_read_end)
      
      read_child_messages if ready.has_key?(:child_msgs)

      # Send the tracking code for the child processes the final notifications
      # and remove them from the children hash. At this point we know that
      # no messages are waiting in the child queue.
      finalize_children
      
      if ready.has_key?(:control_pipe)
        # Consume the data (not important)
        cp_read_end.read_nonblock(1024)
        return
      end
    end
  end
  
  def finalize_children
    children.
      select { |pid, child| child.stopped? }.
      each { |pid, child| child.finalize }

    children.delete_if { |pid, child| 
      child.removable? }
  end

  def read_child_messages
    loop do
      ready = Cod.select(0.1, @master)
      break unless ready
      
      handle_message @master.get
    end
  end
  
  # Called for every message sent from a child. The +msg+ param here is a string
  # that still needs decoding. 
  #
  def handle_message(msg)
    pid, obj = msg
    
    if child=children[pid]
      child.incoming_message(obj)
    else
      warn "Communication from child #{pid} received, but child is gone."
    end
  end
      
  # Calls completion handlers for all the childs that have now exited.
  #     
  def reap_childs
    loop do
      child_pid, status = Process.waitpid(-1, Process::WNOHANG)
      break unless child_pid

      # Trigger the completion callback
      if child=children[child_pid]
        child.sigchld_received 
        # Maybe there are messages queued for this child. If nothing is queued
        # up, the thread will hang in the select in #wait_for_event unless
        # we wake it up. 
        wakeup
      end
    end
  rescue Errno::ECHILD
    # Ignore: This means that no childs remain. 
  end
  
  # Spawns a process to work on +task+. If a block is given, it is called when
  # the task completes. This method should only be called from a strategy
  # inside the dispatchers thread. Otherwise it will expose threading issues. 
  #
  # @example 
  #   create_process(wi) { puts "Task is complete" }
  #
  # @param task [Procrastinate::Task::Callable] task to be run inside the
  #   forked process
  # @param completion_handler [Proc] completion handler that is called when
  #   the process exits
  # @return [void]
  #
  def create_process(task, &completion_handler)
    # Tasks that are interested in getting messages from their childs must 
    # provide a result object that handles incoming 'result' messages.
    result = task.result
    
    pid = fork do
      cleanup
            
      if result
        endpoint = lambda { |obj| @child.put [Process.pid, obj] }
        task.run(endpoint)
      else
        task.run(nil)
      end

      exit! # this seems to be needed to avoid rspecs cleanup tasks
    end
        
    # This should never fire: New children are spawned only after we loose 
    # track of the old ones because they have been successfully processed.
    fail "PID REUSE!" if children.has_key?(pid)
    
    # The spawning is done in the same thread as the reaping is done. This is 
    # why no race condition to the following line exists. (or in other code, 
    # for that matter.)
    children[pid] = ChildProcess.new(completion_handler, result).
      tap { |s| s.start }
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
    until children.empty?
      wait_for_event
      reap_childs
      finalize_children
    end
  end

  # Kills all running processes by sending them a QUIT signal. 
  #
  # @param signal [String] signal to send to the forked processes.
  #
  def kill_processes(signal='QUIT')
    children.each do |pid, process|
      Process.kill(signal, pid)
    end
  end
end
