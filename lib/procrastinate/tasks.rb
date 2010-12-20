
# A collection of tasks that can be performed with procrastinate. 
#
module Procrastinate::Task  
  # Constructs an object of type +klass+ and calls a method on it. 
  #
  class MethodCall
    attr_reader :i
    attr_reader :m
    attr_reader :a
    attr_reader :b
    
    def initialize(instance, method, arguments, block)
      @i = instance
      @m = method
      @a = arguments
      @b = block
    end
    
    def run
      @i.send(@m, *@a, &@b)
    end
  end
end