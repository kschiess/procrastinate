require 'thread'

class Procrastinate::Scheduler
  attr_reader :work_queue
  attr_reader :dispatcher
  def initialize
    @work_queue = Queue.new
  end
  
  def start(worker_klass)
    @dispatcher = Procrastinate::Dispatcher.start(work_queue, worker_klass)
    
    return Procrastinate::Proxy.new(worker_klass, work_queue)
  end
  
  def shutdown
    dispatcher.shutdown
  end
end