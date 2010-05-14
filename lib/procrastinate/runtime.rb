
# An instance of this class obtained from the scheduler can be used to perform
# synchronisation and other communication with the scheduler. 
#
class Procrastinate::Runtime
  def lock(name)
    lock = Procrastinate::Lock.new(name)
    
    lock.synchronize do
      yield
    end
  end
end