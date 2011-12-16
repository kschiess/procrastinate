# A proxy class that will translate all method calls made on it to method 
# calls inside their own process via the Scheduler. 
#
class Procrastinate::Proxy
  # Create a new proxy class. +worker+ is an instance of the class that we 
  # want to perform work in, +scheduler+ is where the work will be scheduled. 
  # Don't call this on your own, instead use Scheduler#proxy. 
  #
  def initialize(worker, scheduler) # :nodoc: 
    @worker = worker
    @scheduler = scheduler
  end
  
  def respond_to?(name)
    @worker.respond_to?(name)
  end
  
  def method_missing(name, *args, &block)
    if respond_to? name
      task = Procrastinate::Task::Callable.new(
        lambda { @worker.send(name, *args, &block) })
      @scheduler.schedule(task)
      
      return task.result
    else
      super
    end
  end
end