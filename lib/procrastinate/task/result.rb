
require 'thread'

# A single value result, like from a normal method call. Return an instance of
# this from your task#result method to enable result handling. 
#
class Procrastinate::Task::Result
  def initialize
    @wakeup_m       = Mutex.new
    @wakeup         = []
    
    @value_ready    = false
    @value          = nil
  end
  
  # Gets passed all messages sent by the child process for this task.
  #
  def incoming_message(obj)
    return if ready?
    
    @value = obj
    @value_ready = true
    
    @wakeup_m.synchronize do
      @wakeup.each { |t| t.run }
    end
  end

  def value
    while not ready?
      @wakeup_m.synchronize do
        @wakeup << Thread.current
      end
      sleep
    end
    
    @value
  end
  
  def ready?
    @value_ready
  end
end