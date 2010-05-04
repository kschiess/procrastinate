
require 'blankslate'

class Procrastinate::Proxy < BlankSlate
  def initialize(methods, scheduler)
    @methods = methods
    @scheduler = scheduler
  end
  
  def respond_to?(name)
    @methods.include?(name)
  end
  
  def method_missing(name, *args, &block)
    if respond_to? name
      @scheduler.schedule [name, args, block]
    else
      super
    end
  end
end