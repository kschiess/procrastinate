
# A dispatcher strategy that throttles tasks starting and ensures that no
# more than limit processes run concurrently. 
#
class Procrastinate::DispatchStrategy::Throttled
  attr_reader :queue
  attr_reader :limit, :current
  
  # Client thread
  def initialize(limit)
    @queue = Queue.new
    @shutdown_requested = false
    
    @limit = limit
    @current = 0
  end

  # All threads
  def shutdown_requested?
    @shutdown_requested
  end

  # Client thread
  def schedule(task)
    raise ShutdownRequested if shutdown_requested?
    
    queue.push task
  end
  
  # Dispatcher thread
  def spawn_new_workers(dispatcher)
    # Spawn tasks
    spawn(dispatcher) while should_spawn?

    # If the queue is empty now, maybe shutdown the dispatcher
    dispatcher.request_stop if shutdown_requested? && queue.empty?
  end
  
  # Dispatcher thread
  def spawn(dispatcher)
    dispatcher.spawn(queue.pop) { @current -= 1 }
    @current += 1
  end
  # Dispatcher thread
  def should_spawn?
    (not queue.empty?) &&
      current < limit
  end
  
  # Client thread
  def shutdown
    @shutdown_requested = true
  end
end