
require 'thread'

class Procrastinate::DispatchStrategy::Simple
  attr_reader :queue
  
  def initialize
    @queue = Queue.new
    @shutdown_requested = false
  end
  
  def shutdown_requested?
    @shutdown_requested
  end

  def schedule(task)
    raise ShutdownRequested if shutdown_requested?
    
    queue.push task
  end
  
  def spawn_new_workers(dispatcher)
    # Spawn tasks
    dispatcher.spawn queue.pop until queue.empty?

    # If the queue is empty now, maybe shutdown the dispatcher
    dispatcher.request_stop if shutdown_requested? && queue.empty?
  end
  
  def shutdown
    @shutdown_requested = true
  end
end