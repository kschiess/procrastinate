
require 'procrastinate/task/result'

# Constructs an object of type +klass+ and calls a method on it. 
#
class Procrastinate::Task::MethodCall
  include Procrastinate::Task
  
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
  
  # Runs this task. Gets passed an endpoint that can be used to communicate
  # values back to the master. Every time you write a value to that endpoint
  # (using #send), the server will call #incoming_message on the task object
  # in the master process. This allows return values and other communication
  # from children to the master (and to the caller in this case).
  #
  def run(endpoint)
    r = @i.send(@m, *@a, &@b)
    endpoint.send r if endpoint
  end
  
  def result
    @result ||= Result.new
  end
end
