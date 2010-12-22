
require 'thread'

# A single value result, like from a normal method call. Return an instance of
# this from your task#result method to enable result handling. 
#
class Procrastinate::Task::Result
  class OneTimeFlag
    def initialize
      @waiting   = []
      @waiting_m = Mutex.new
      @set       = false
    end
    
    # If the flag is set, does nothing. If it isn't, it blocks until the flag
    # is set. 
    def wait
      return if set?
      
      @waiting_m.synchronize do
        @waiting << Thread.current
        @waiting_m.sleep(0.001) until set?
      end
    end
    
    # Sets the flag and releases all waiting threads.
    #
    def set
      @set = true
      @waiting_m.synchronize do
        @waiting.each { |t| t.run }
        @waiting = [] # cleanup
      end
    end
    
    # Non blocking: Is the flag set?
    #
    def set?
      @set
    end
    
    if RUBY_VERSION =~ /^1.8/
      def wait
      end
      
      def signal
      end
    end
  end
  
  def initialize
    @value_ready    = OneTimeFlag.new
    @value          = nil
    @exception      = false
  end
  
  # Gets passed all messages sent by the child process for this task.
  #
  def incoming_message(obj)
    return if ready?
    
    @value = obj
    @value_ready.set
  end
  
  # Notifies this result that the process has died. If this happens before
  # a process result is passed to #incoming_message, that message will never
  # arrive. 
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