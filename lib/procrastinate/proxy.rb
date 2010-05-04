
require 'blankslate'

class Procrastinate::Proxy < BlankSlate
  def initialize(klass, scheduler)
    @klass = klass

    # The .map is needed for ruby 1.8
    @valid_methods = klass.instance_methods.map { |m| m.to_sym }

    @scheduler = scheduler
  end
  
  def respond_to?(name)
    @valid_methods.include?(name)
  end
  
  def method_missing(name, *args, &block)
    if respond_to? name
      @scheduler.schedule( 
        Procrastinate::Task::MethodCall.new(@klass, name, args, block))
    else
      super
    end
  end
end