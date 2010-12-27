# A class that acts as a filter between ProcessManager and the endpoint it
# uses to communicate with its children. This converts Ruby objects into
# Strings and also sends process id. 
#
class Procrastinate::ProcessManager::ObjectEndpoint < Struct.new(:endpoint, :pid)
  def send(obj)
    msg = Marshal.dump([pid, obj])
    endpoint.send(msg)
  end
end