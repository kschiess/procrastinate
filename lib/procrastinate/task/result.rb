
require 'thread'

# A single value result, like from a normal method call. Return an instance of
# this from your task#result method to enable result handling. 
#
class Procrastinate::Task::Result
  def initialize
    @mutex = Mutex.new

    @value_ready_cv = ConditionVariable.new
    @value_ready    = false
    @value          = nil
    
    p [:initialize, object_id]
  end
  
  # Gets passed all messages sent by the child process for this task.
  #
  def incoming_message(obj)
    @mutex.synchronize do
      return if ready?    # discard.

      @value = obj

      @value_ready = true
      @value_ready_cv.broadcast
    end
  end

  def value
    p [:value, object_id, Thread.current]
    @mutex.synchronize do
      while not ready?
        p :not_ready
        @value_ready_cv.wait(@mutex)
        p :ready?, ready?
      end
    end
    
    @value
  end
  
  def ready?
    @value_ready
  end
end