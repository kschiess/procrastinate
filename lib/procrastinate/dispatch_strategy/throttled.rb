
# A dispatcher strategy that throttles tasks starting and ensures that no
# more than limit processes run concurrently. 
#
class Procrastinate::DispatchStrategy::Throttled < Procrastinate::DispatchStrategy::Simple
  attr_reader :limit, :current
  
  # Client thread
  def initialize(limit)
    super()
    
    @limit = limit
    @current = 0
  end
  
  # Dispatcher thread
  def spawn(dispatcher)
    super(dispatcher) { @current -= 1 }
    @current += 1
  end
  def should_spawn?
    super &&
      current < limit
  end
end