
class Procrastinate::Dispatcher
  def self.start(queue, worker_klass)
    new(queue, worker_klass).tap do |dispatcher| 
      dispatcher.start
    end
  end
  def start
    @thread = Thread.start do
      loop do
        work_item = queue.pop
        break if work_item == :shutdown_request
        
        worker = worker_klass.new
        message, arguments, block = work_item
        worker.send(message, *arguments, &block)
      end
    end
    
    thread.abort_on_exception = true
  end
  
  attr_reader :queue, :worker_klass
  attr_reader :thread
  def initialize(queue, worker_klass)
    @queue = queue
    @worker_klass = worker_klass
  end

  def shutdown
    queue.push(:shutdown_request)
    thread.join
  end
end
