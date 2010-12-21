
# A communication endpoint. This acts as a factory and hub for the whole 
# IPC library.
#
module Procrastinate::IPC::Endpoint
  def anonymous
    Anonymous.new
  end
  module_function :anonymous
  
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
    def initialize(pipe)
      @pipe = pipe
    end
    
    def receive(timeout=nil)
      pipe.read_nonblock(1024*1024*1024)
    end
  end
  
  class Anonymous::Client
    attr_reader :pipe
    def initialize(pipe)
      @pipe = pipe
    end

    def send(msg)
      pipe.write(msg)
    end
  end
end