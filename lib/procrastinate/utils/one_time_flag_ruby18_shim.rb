class Procrastinate::Utils::OneTimeFlag
  def initialize
    @waiting_m  = Mutex.new
    @waiting_cv = ConditionVariable.new
    @set        = false
  end
  
  # If the flag is set, does nothing. If it isn't, it blocks until the flag
  # is set. 
  def wait
    return if set?
    
    @waiting_m.synchronize do
      @waiting_cv.wait(@waiting_m)
    end
  end
  
  # Sets the flag and releases all waiting threads.
  #
  def set
    @set = true
    @waiting_m.synchronize do
      @waiting_cv.broadcast
    end
  end
  
  # Non blocking: Is the flag set?
  #
  def set?
    @set
  end
end