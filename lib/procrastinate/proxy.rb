
class Procrastinate::Proxy
  def initialize(worker, scheduler)
    @worker = worker
    @scheduler = scheduler
  end
  
  def respond_to?(name)
    @worker.respond_to?(name)
  end
  
  def method_missing(name, *args, &block)
    if respond_to? name
      @scheduler.schedule( 
        Procrastinate::Task::MethodCall.new(@worker, name, args, block))
    else
      super
    end
  end
end