
# A dispatcher strategy that throttles tasks starting and ensures that no
# more than limit processes run concurrently. 
#
class Procrastinate::SpawnStrategy::Throttled < Procrastinate::SpawnStrategy::Simple
  attr_reader :limit, :current
  
  # Client thread
  def initialize(limit)
    super()
    
    @limit = limit
    @current = 0
  end
  
  def should_spawn?
    current < limit
  end
  
  def notify_spawn
    @current += 1
    warn "Throttled reports too many births!" if current > limit
  end
  
  def notify_dead
    @current -= 1
    warn "Throttled reports more deaths than births?!" if current < 0
  end
end