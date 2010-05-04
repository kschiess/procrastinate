
class Procrastinate::Dispatcher
  attr_reader :queue, :worker_klass
  attr_reader :thread
  attr_reader :child_pids
  def initialize(queue, worker_klass)
    @queue = queue
    @worker_klass = worker_klass
    @child_pids = []
  end

  def self.start(queue, worker_klass)
    new(queue, worker_klass).tap do |dispatcher| 
      dispatcher.start
    end
  end
  def start
    register_signals

    @thread = Thread.new do
      loop do
        work_item = queue.pop
        break if work_item == :shutdown_request

        dispatch work_item
      end
    end
    
    thread.abort_on_exception = true
  end
  
  def register_signals
    # Reap childs that have finished. 
    Signal.trap("CHLD") {
      begin 
        child_pid = Process.wait
        
        # TODO: Is this safe?
        child_pids.delete(child_pid)
      rescue Errno::ECHILD
      else
        # puts "Child #{status.pid} died."
      end
    }
    
    # Signal.trap("TERM") { shutdown }
  end
  
  def dispatch(work_item)
    @child_pids << fork do
      worker = worker_klass.new
      message, arguments, block = work_item
      worker.send(message, *arguments, &block)
      
      exit 0
    end
  end

  def shutdown
    queue.push(:shutdown_request)
    thread.join

    unless child_pids.empty?
      until child_pids.empty?
        sleep 0.3 
      end
    end
  end
end
