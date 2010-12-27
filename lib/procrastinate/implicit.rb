
require 'procrastinate'

module Procrastinate
  # call-seq:
  #   Procrastinate.scheduler => scheduler
  #
  # Returns the scheduler instance. When using procrastinate/implicit, there
  # is one global scheduler to your ruby process, this one.
  #
  def scheduler
    @scheduler ||= Scheduler.start
  end
  module_function :scheduler
  
  # call-seq: 
  #   Procrastinate.proxy(obj) => proxy
  #
  # Creates a proxy that will execute methods called on obj in a child process. 
  #
  # Example: 
  #
  #   proxy = Procrastinate.proxy("foo")
  #   r     = proxy += "bar"
  #   r.value   # => 'foobar'
  #
  def proxy(obj)
    scheduler.proxy(obj)
  end
  module_function :proxy
  
  # call-seq: 
  #   Procrastinate.join
  #
  # Waits for all currently scheduled tasks to complete. This is like calling
  # #value on all result objects, except that nothing is returned.
  #
  # Example: 
  #
  #   proxy = Procrastinate.proxy("foo")
  #   r     = proxy += "bar"
  #   Procrastinate.join
  #   r.ready? # => true
  #
  def join
    scheduler.join
  end
  module_function :join
  
  # Internal method: You should not have to shutdown the scheduler manually
  # since it consumes almost no resources when not active. This is mainly
  # useful in tests to achieve isolation. 
  #
  def shutdown
    scheduler.shutdown
  end
  module_function :shutdown
end