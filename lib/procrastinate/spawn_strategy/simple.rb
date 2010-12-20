
class Procrastinate::SpawnStrategy::Simple
  def should_spawn?
    true
  end
  
  def notify_spawn
  end
  
  def notify_dead
  end
end