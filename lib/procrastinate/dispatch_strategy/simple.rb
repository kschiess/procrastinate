

class Procrastinate::DispatchStrategy::Simple
  def initialize(queue)
    @queue = queue
  end
  
  def notify_task_completion(pid)
  end
  
  def spawn_new_workers(spawner)
    # can call #spawn on spawner to spawn new workers
  end
end