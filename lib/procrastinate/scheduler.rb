require 'thread'

class Procrastinate::Scheduler
  attr_reader :work_queue
  attr_reader :dispatcher
  attr_reader :strategy
  
  def initialize
    @work_queue = Queue.new
  end
  
  def start(worker_klass)
    @strategy   = Procrastinate::DispatchStrategy::Simple.new(work_queue)
    @dispatcher = Procrastinate::Dispatcher.start(strategy, worker_klass)

    # The .map is needed for ruby 1.8
    valid_methods = worker_klass.instance_methods.map { |m| m.to_sym }
    return Procrastinate::Proxy.new(valid_methods, self)
  end
  
  # Called by the proxy to schedule work. A work item is a triple of 
  # <method_name, arguments, block>. 
  #
  def schedule(work_item)
    work_queue.push work_item
    
    dispatcher.wakeup
  end
  
  def shutdown
    dispatcher.shutdown
  end
end