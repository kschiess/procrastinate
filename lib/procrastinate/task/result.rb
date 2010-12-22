
require 'procrastinate/utils'

# A single value result, like from a normal method call. Return an instance of
# this from your task#result method to enable result handling. 
#
class Procrastinate::Task::Result
  def initialize
    @value_ready    = Procrastinate::Utils::OneTimeFlag.new
    @value          = nil
    @exception      = false
  end
  
  # Gets passed all messages sent by the child process for this task.
  #   *control thread* 
  #
  def incoming_message(obj)
    return if ready?
    
    @value = obj
    @value_ready.set
  end
  
  # Notifies this result that the process has died. If this happens before
  # a process result is passed to #incoming_message, that message will never
  # arrive. 
  #   *control thread* 
  #
  def process_died
    return if ready?
    
    @exception = true    
    @value_ready.set
  end

  def value
    @value_ready.wait
    
    if @exception
      raise Procrastinate::ChildDeath, "Child process died before producing a value."
    else
      @value
    end
  end
  
  def ready?
    @value_ready.set?
  end
end