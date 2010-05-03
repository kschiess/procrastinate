
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
      # loop do
        work_item = queue.pop
        break if work_item == :shutdown_request

        dispatch work_item
      # end
    end
    
    thread.abort_on_exception = true
  end
  
  def register_signals
    # Reap childs that have finished. 
    p :register_trap
    Signal.trap("CHLD") {
      p :sigchld
      # begin 
      #   child_pid = Process.wait
      #   p [:exit, child_pid]
      #   
      #   # TODO: Is this safe?
      #   puts "Child #{child_pid} exited with #{status.inspect}"
      #   child_pids.delete(child_pid)
      # rescue Errno::ECHILD
      # else
      #   # puts "Child #{status.pid} died."
      # end
    }
    
    # Signal.trap("TERM") { shutdown }
  end
  
  def dispatch(work_item)
    @child_pids << fork do
      p [:child, Process.pid]
      worker = worker_klass.new
      p :d1
      message, arguments, block = work_item
      p :d2
      worker.send(message, *arguments, &block)
      p :d3
      
      exit 0
    end
    p :end_of_dispatch
  end

  def shutdown
    queue.push(:shutdown_request)
    thread.join

p :shutdown
    unless child_pids.empty?
      until child_pids.empty?
        p [:wait, child_pids]
        sleep 0.3 
      end
    end
  end
end
