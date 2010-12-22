
require 'thread'

# A single value result, like from a normal method call. Return an instance of
# this from your task#result method to enable result handling. 
#
class Procrastinate::Task::Result
  def initialize
    @result_ready   = ConditionVariable.new
    @result_mutex   = Mutex.new
    
    @value_ready    = false
    @value          = nil
    @exception      = false
  end
  
  # Gets passed all messages sent by the child process for this task.
  #
  def incoming_message(obj)
    return if ready?
    
    @value = obj
    @value_ready = true
    
    signal_ready
  end
  
  # Notifies this result that the process has died. If this happens before
  # a process result is passed to #incoming_message, that message will never
  # arrive. 
  #
  def process_died
    return if ready?
    
    @exception = true
    @value_ready = true
    
    signal_ready
  end

  def value
    wait_for_value
    
    if @exception
      raise Procrastinate::ChildDeath, "Child process died before producing a value."
    else
      @value
    end
  end
  
  def ready?
    @value_ready
  end
  
private
  # Puts the thread to sleep and queues it into @wakeup. Only wake up once
  # ready? is true.
  #
  def wait_for_value
    return if ready?    # quick return for clear cases

    @result_mutex.synchronize do
      @result_ready.wait(@result_mutex)
    end
  end
  
  # Tells all waiting threads that ready? is now true.
  #
  def signal_ready
    @result_ready.broadcast
  end
end