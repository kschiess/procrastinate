
class Procrastinate::DispatchStrategy::Simple
  def should_spawn?
    true
  end
  
  def notify_spawn
  end
  
  def notify_dead
  end
end