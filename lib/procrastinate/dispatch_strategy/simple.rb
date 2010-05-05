
require 'thread'

class Procrastinate::DispatchStrategy::Simple
  attr_reader :queue

  # Client thread
  def initialize
    @queue = Queue.new
    @shutdown_requested = false
  end
  
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
  
  
  # Spawn a new task from the job queue. 
  # Dispatcher thread
  #
  def spawn(dispatcher, &block)
    dispatcher.spawn(queue.pop, &block)
  end
  def should_spawn?
    not queue.empty?
  end
  
  def shutdown
    @shutdown_requested = true
  end
end