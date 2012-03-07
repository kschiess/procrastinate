
require 'procrastinate/task/result'

module Procrastinate::Task
  # A task that calls the block and returns the result of execution. 
  #
  class Callable
    attr_reader :block
    attr_reader :result
    
    def initialize(block)
      @b = block
      @result = Result.new
    end
  
    # Runs this task. Gets passed an endpoint that can be used to communicate
    # values back to the master. Every time you write a value to that endpoint
    # (using #send), the server will call #incoming_message on the task object
    # in the master process. This allows return values and other communication
    # from children to the master (and to the caller in this case).
    #
    def run(endpoint)
      r = @b.call
      endpoint.call(r) if endpoint
    end
  end
end