
require 'procrastinate'

module Procrastinate
  # Returns the scheduler instance. When using procrastinate/implicit, there
  # is one global scheduler to your ruby process, this one.
  # 
  # @return [Scheduler] singleton scheduler for implicit scheduling.
  #
  def scheduler
    @scheduler ||= Scheduler.start
  end
  module_function :scheduler
  
  # Creates a proxy that will execute methods called on obj in a child process. 
  #
  # @example 
  #   proxy = Procrastinate.proxy("foo")
  #   r     = proxy += "bar"
  #   r.value   # => 'foobar'
  #
  # @param obj [Object] Ruby object that the calls need to be proxied to
  # @return [Proxy] proxy object that will execute method calls in child 
  #   processes
  #
  def proxy(obj)
    scheduler.proxy(obj)
  end
  module_function :proxy
  
  # Schedules a block to be executed in its own thread. Returns the future that 
  # will return the blocks return value. 
  #
  # @example
  #   r = Procrastinate.schedule { do_some_work }
  #   r.value                                     # => the blocks return value
  #
  # @param block [Proc] block that will be executed in a child process
  # @return [Task::Result] a promise for the blocks return value
  #
  def schedule(&block)
    scheduler.schedule(&block)
  end
  module_function :schedule
  
  # Waits for all currently scheduled tasks to complete. This is like calling
  # #value on all result objects, except that nothing is returned.
  #
  # @example 
  #   proxy = Procrastinate.proxy("foo")
  #   r     = proxy += "bar"
  #   Procrastinate.join
  #   r.ready? # => true
  #
  # @return [void]
  #
  def join
    scheduler.join
  end
  module_function :join
  
  # Internal method: You should not have to shutdown the scheduler manually
  # since it consumes almost no resources when not active. This is mainly
  # useful in tests to achieve isolation. 
  #
  # @private
  #
  def shutdown
    scheduler.shutdown
  end
  module_function :shutdown
  
  # Resets the implicit scheduler. Please use this only in tests, not in
  # production code. 
  #
  def reset
    scheduler.shutdown
    @scheduler = nil
  end
  module_function :reset
end