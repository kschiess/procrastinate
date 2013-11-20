# A <completion handler, result> tuple that stores the handler to call when
# a child exits and the object that will handle child-master communication
# if desired.
#
Procrastinate::ProcessManager::ChildProcess = 
  Struct.new(:handler, :result, :state) do

  attr_reader :master_pipe, :child_pipe
  
  def initialize(handler, result)
    super(handler, result, "new")

    @master_pipe, @child_pipe = IO.pipe
  end
  
  state_machine :state, :initial => :new do
    event(:start)             { transition :new => :running }
    event(:sigchld_received)  { transition :running => :stopped }
    event(:finalize)          { transition :stopped => :removable }
    
    after_transition :on => :sigchld_received, 
      :do => :call_completion_handlers
    after_transition :on => :finalize, 
      :do => :notify_result
  end
  
  # Calls the completion handler for the child. At this stage, the process is
  # not around anymore, but we still need to do some tracking. 
  #
  def call_completion_handlers
    handler.call if handler
  end
  
  # Notifies the childs result value that the child has died and that no
  # more messages will be read. If this is the only notification, the result
  # will yield a ChildDeath exception.
  #
  def notify_result
    result.process_died if result

    # The child is now officially dead, so we don't need these anymore: 
    @master_pipe.close
    @child_pipe.close
  end
      
  # Handles incoming messages from the tasks process.
  #
  def incoming_message(obj)
    result.incoming_message(obj) if result
  end

  # Read and process a message from the process that is connected to this 
  # object. Normally, we would make sure that such a message is indeed waiting
  # on the master_pipe by means of an IO select. 
  #
  def read_message
    msg = Marshal.load(master_pipe)
    incoming_message(msg)
  end

  def send_message obj
    Marshal.dump(obj, child_pipe)
  end
end
