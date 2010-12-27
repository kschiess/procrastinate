# A <completion handler, result> tuple that stores the handler to call when
# a child exits and the object that will handle child-master communication
# if desired.
#
class Procrastinate::ProcessManager::ChildProcess < Struct.new(:handler, :result, :state)
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
