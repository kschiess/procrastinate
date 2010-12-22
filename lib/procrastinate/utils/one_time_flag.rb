class Procrastinate::Utils::OneTimeFlag
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
end

if RUBY_VERSION =~ /^1.8/
  require 'procrastinate/utils/one_time_flag_ruby18_shim'
end

