
# A collection of tasks that can be performed with procrastinate. 
#
module Procrastinate::Task
  # Constructs an object of type +klass+ and calls a method on it. 
  #
  class MethodCall
    def initialize(instance, method, arguments, block)
      @instance = instance
      @method = method
      @arguments = arguments
      @block = block
    end
    
    def run
      @instance.send(@method, *@arguments, &@block)
    end
  end
end