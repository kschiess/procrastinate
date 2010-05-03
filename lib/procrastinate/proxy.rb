
require 'blankslate'

class Procrastinate::Proxy < BlankSlate
  def initialize(klass, work_queue)
    @klass = klass
    @work_queue = work_queue
  end
  
  def respond_to?(name)
    @klass.instance_methods.include?(name)
  end
  
  def method_missing(name, *args, &block)
    if respond_to? name
      @work_queue.push [name, args, block]
    else
      super
    end
  end
end