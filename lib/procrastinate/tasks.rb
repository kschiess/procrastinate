module Procrastinate::Task
  # Constructs an object of type +klass+ and calls a method on it. 
  #
  class MethodCall
    def initialize(klass, method, arguments, block)
      @klass = klass
      @method = method
      @arguments = arguments
      @block = block
    end
    
    def run
      obj = @klass.new
      obj.send(@method, *@arguments, &@block)
    end
  end
end