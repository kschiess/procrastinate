
# A file based lock below a base directory that is identified by Lock.base. 
#
class Procrastinate::Lock
  class << self
    # Base directory for all lock files that are created. 
    #
    attr_accessor :base
  end
  
  attr_reader :name   # name of the lock
  attr_reader :file   # file handle of the lock
  def initialize(name)
    @name = name
    @file = File.open(
      File.join(
        self.class.base, name), 
      'w+')
  end
  
  def acquire
    file.flock File::LOCK_EX
  end
  def release
    file.flock File::LOCK_UN
  end
end