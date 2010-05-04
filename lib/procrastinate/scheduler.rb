class Procrastinate::Scheduler
  attr_reader :dispatcher
  attr_reader :strategy
  
  def initialize
    @shutdown_requested = false
  end
  
  def start(worker_klass)
    @strategy   = Procrastinate::DispatchStrategy::Simple.new
    @dispatcher = Procrastinate::Dispatcher.start(strategy, worker_klass)
    
    create_proxy(worker_klass)
  end
  
  def create_proxy(worker_klass)
    return Procrastinate::Proxy.new(worker_klass, self)
  end
  
  # Called by the proxy to schedule work. A work item is a triple of 
  # <method_name, arguments, block>. 
  #
  def schedule(work_item)
    strategy.schedule(work_item)
    dispatcher.wakeup
  end
  
  def shutdown
    strategy.shutdown
    dispatcher.join
  end
end