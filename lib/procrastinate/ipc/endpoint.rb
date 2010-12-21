
# A communication endpoint. This acts as a factory and hub for the whole 
# IPC library.
#
module Procrastinate::IPC::Endpoint
  def anonymous
    Anonymous.new
  end
  module_function :anonymous
  
  # Works the same as IO.select, only that it doesn't care about write and 
  # error readiness, only read. You can mix IPC::Endpoints and normal IO
  # instances freely. 
  #
  def select(read_array, timeout=nil)
    # This maps real system IO instances to wrapper objects. Return the thing
    # to the right if IO.select returns the thing to the left. 
    mapping = Hash.new
    
    read_array.each { |io_or_endpoint| 
      if io_or_endpoint.respond_to?(:select_ios)
        io_or_endpoint.select_ios.each do |io|
          mapping[io] = io_or_endpoint
        end
      else
        mapping[io_or_endpoint] = io_or_endpoint
      end
    }
    
    system_io = IO.select(mapping.keys, nil, nil, timeout)
    if system_io
      return system_io.first.
        # Map returned selectors to their object counterparts and then only
        # return once (if more than one was returned).
        map { |e| mapping[e] }.uniq   
    end
  end
  module_function :select
  
  class Anonymous
    def initialize
      @re, @we = IO.pipe
    end
    
    def server
      Server.new(@re)
    end
    def client
      Client.new(@we)
    end
  end
  
  class Anonymous::Server
    attr_reader :pipe
    attr_reader :waiting
    def initialize(pipe)
      @pipe = pipe
      @waiting = Array.new
    end
    
    def receive(timeout=nil)
      return waiting.shift if waiting?
      
      loop do
        buffer = pipe.read_nonblock(1024*1024*1024)
      
        while buffer.size > 0
          size = buffer.slice!(0...4).unpack('l').first
          waiting << buffer.slice!(0...size)
        end
      
        return waiting.shift if waiting?
      end
    end
    
    # True if there are queued messages in the Endpoint stack. If this is 
    # false, a receive might block. 
    #
    def waiting?
      not waiting.empty?
    end
    
    # Return underlying IOs for select.
    #
    def select_ios
      [@pipe]
    end
  end
  
  class Anonymous::Client
    attr_reader :pipe
    def initialize(pipe)
      @pipe = pipe
    end

    def send(msg)
      buffer = [msg.size].pack('l') + msg
      pipe.write(buffer)
    end
  end
end