
require 'state_machine'

# Dispatches and handles tasks and task completion. Only low level unixy
# manipulation here, no strategy. The only methods you should call from the
# outside are #setup, #step, #wakeup and #shutdown. 
#
class Procrastinate::ProcessManager
  include Procrastinate::IPC
  
  # This pipe is used to wait for events in the master process. 
  attr_reader :control_pipe
  
  # A hash of <pid, callback> that contains callbacks for all the child
  # processes we spawn. Once the process is complete, the callback is called
  # in the procrastinate thread.
  attr_reader :children
  
  # A class that acts as a filter between ProcessManager and the endpoint it
  # uses to communicate with its children. This converts Ruby objects into
  # Strings and also sends process id. 
  #
  class ObjectEndpoint < Struct.new(:endpoint, :pid)
    def send(obj)
      msg = Marshal.dump([pid, obj])
      endpoint.send(msg)
    end
  end
  
  # A <completion handler, result> tuple that stores the handler to call when
  # a child exits and the object that will handle child-master communication
  # if desired.
  #
  class Child < Struct.new(:handler, :result, :state)
    state_machine :state, :initial => :new do
      event(:start) { transition :new => :running }
      event(:died)  { transition :running => :dead }
      
      after_transition :on => :died, :do => :call_completion_handlers
    end
    
    # Calls the completion handler for the child. This is triggered by the
    # transition into the 'dead' state. 
    #
    def call_completion_handlers
      result.process_died if result
      handler.call if handler
    end
        
    # Handles incoming messages from the tasks process.
    #
    def incoming_message(obj)
      result.incoming_message(obj) if result
    end
  end
  
  def initialize
    # This controls process manager wakeup
    @control_pipe = IO.pipe
    
    # All presently running children
    @children = {}
    
    # Child Master Communication (cmc)
    endpoint = Endpoint.anonymous
    @cmc_server = endpoint.server
    @cmc_client = endpoint.client
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
    cp_read_end = control_pipe.first
    
    loop do # until we have input in the cp_read_end (control_pipe)
      ready = Endpoint.select([cp_read_end, @cmc_server])
      
      read_child_messages if ready.include? @cmc_server

      # Kill children here, since we've just depleted the communication
      # endpoint. This avoids the situation where the child process
      # communicates but we remove it from our records before it can be told
      # about it.
      kill_children
      
      if ready.include? cp_read_end
        # Consume the data (not important)
        cp_read_end.read_nonblock(1024)
        return
      end
    end

  # rescue Errno::EAGAIN, Errno::EINTR
    # TODO Is this needed?
    # A signal has been received. Mostly, this is as if we had received
    # something in the control pipe.
  end
  
  def kill_children
    children.delete_if { |pid, child| child.dead? }
  end

  # Once the @cmc_server endpoint is ready, loops and reads all child communication. 
  #
  def read_child_messages
    loop do
      msg = @cmc_server.receive
      decode_and_handle_message(msg)
      
      break unless @cmc_server.waiting?
    end
  end
  
  # Called for every message sent from a child. The +msg+ param here is a string
  # that still needs decoding. 
  #
  def decode_and_handle_message(msg)
    pid, obj = Marshal.load(msg)
    if child=children[pid]
      child.incoming_message(obj)
    else
      warn "Communication from child #{pid} received, but child is gone."
    end
  rescue => b
    # Messages that cannot be unmarshalled will be ignored. 
    warn "Can't unmarshal child communication."
  end
      
  # Calls completion handlers for all the childs that have now exited.
  #     
  def reap_childs
    loop do
      child_pid, status = Process.waitpid(-1, Process::WNOHANG)
      break unless child_pid

      # Trigger the completion callback
      if child=children[child_pid]
        child.died 
      end
    end
  rescue Errno::ECHILD
    # Ignore: This means that no childs remain. 
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
    # Tasks that are interested in getting messages from their childs must 
    # provide a result object that handles incoming 'result' messages.
    result = task.result
    
    pid = fork do
      cleanup
            
      if result
        endpoint = ObjectEndpoint.new(@cmc_client, Process.pid)
        task.run(endpoint)
      else
        task.run(nil)
      end

      exit! # this seems to be needed to avoid rspecs cleanup tasks
    end
    
    # The spawning is done in the same thread as the reaping is done. This is 
    # why no race condition to the following line exists. (or in other code, 
    # for that matter.)
    children[pid] = Child.new(completion_handler, result).tap { |s| s.start }
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
    until children.all? { |p, c| c.dead? }
      wait_for_event
      reap_childs
    end
  end
end
