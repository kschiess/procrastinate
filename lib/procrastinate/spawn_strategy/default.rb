
# A dispatcher strategy that throttles tasks starting and ensures that no more
# than limit processes run concurrently. Limit is initialized to the number of
# cores this system has (+1) or a default value of 5 processes if the number
# of cores cannot be autodetected.
#
class Procrastinate::SpawnStrategy::Default < Procrastinate::SpawnStrategy::Throttled
  def initialize(workload_factor=3)
    # In reality, this depends on what workload you have. You might want to 
    # tune this number.
    super(autodetect_cores*workload_factor)
  end
  
  def autodetect_cores
    # Linux / all OS with a /proc filesystem
    if File.exist?('/proc/cpuinfo')
      return Integer(`cat /proc/cpuinfo | grep "processor" | wc -l`.chomp)
    end
      
    # Mac OS X 
    if File.exist?('/usr/sbin/system_profiler')
      output = `system_profiler SPHardwareDataType | grep "Total Number Of Cores"`
      if md=output.match(%r(Total Number Of Cores: (\d+)))
        return Integer(md[1])
      end
    end
    
    warn "Could not detect the number of CPU cores. Using a default of 2."
    return 2
  end
end