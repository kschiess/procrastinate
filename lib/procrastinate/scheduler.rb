class Procrastinate::Scheduler
  attr_reader :dispatcher
  attr_reader :strategy
  
  def initialize
    @shutdown_requested = false
  end
  
  # Start a new scheduler
  def self.start(strategy=nil)
    new.start(strategy)
  end
  def start(strategy=nil)
    @strategy   = strategy || Procrastinate::DispatchStrategy::Simple.new
    @dispatcher = Procrastinate::Dispatcher.start(@strategy)
    
    self
  end
  
  def create_proxy(worker)
    return Procrastinate::Proxy.new(worker, self)
  end
    
  # Called by the proxy to schedule work.
  #
  def schedule(task)
    strategy.schedule(task)
    dispatcher.wakeup
  end
  
  def shutdown
    strategy.shutdown
    dispatcher.join
  end
end