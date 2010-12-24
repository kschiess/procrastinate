
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
    scheduler.create_proxy(obj)
  end
  module_function :proxy
  
  # Internal method: You should not have to shutdown the scheduler manually
  # since it consumes almost no resources when not active. This is mainly
  # useful in tests to achieve isolation. 
  #
  def shutdown
    scheduler.shutdown
  end
  module_function :shutdown
end