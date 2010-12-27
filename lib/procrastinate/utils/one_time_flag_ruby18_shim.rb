class Procrastinate::Utils::OneTimeFlag
  def initialize
    @set        = false
  end
  
  # If the flag is set, does nothing. If it isn't, it blocks until the flag
  # is set. 
  def wait
    return if set?
    
    sleep(0.01) until set?
  end
  
  # Sets the flag and releases all waiting threads.
  #
  def set
    @set = true
  end
  
  # Non blocking: Is the flag set?
  #
  def set?
    @set
  end
end