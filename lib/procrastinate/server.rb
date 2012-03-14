module Procrastinate
  class Server
    def initialize
      @manager  = Procrastinate::ProcessManager.new
      @state    = :new
    end
    
    def start(n, activity_check_interval=nil, &block)
      fail "Already running server." unless @state == :new
      
      @block    = block
      @strategy = Procrastinate::SpawnStrategy::Throttled.new(n)
      @state    = :running
      @check_interval = activity_check_interval
      
      start_thread
    end
    
    def shutdown
      fail "For shutdown, server must be running." unless @state == :running

      @state = :shutdown
      @manager.wakeup
      
      @thread.join if @thread
      
      @thread = nil
      @state  = :new
    end
    
  private
    def start_thread
      @thread = Thread.start(&method(:control_thread_main))
    end
    
    # @note This method runs in the control thread only.
    #
    def spawn_new_workers
      while @strategy.should_spawn?
        task = Procrastinate::Task::Callable.new(@block)
        
        @strategy.notify_spawn
        @manager.create_process(task) do
          @strategy.notify_dead
        end
      end
    end
    
    # @note This method runs in the control thread only.
    #
    def control_thread_main
      # Start managers work
      @manager.setup

      # Loop until someone requests a shutdown.
      loop do
        spawn_new_workers

        @manager.step
        
        break if @state == :shutdown
      end
      
      @manager.kill_processes
      @manager.teardown
    rescue => ex
      # Sometimes exceptions vanish silently. This will avoid that, even though
      # they should abort the whole process.

      warn "Exception #{ex.inspect} caught."
      ex.backtrace.first(5).each do |line|
        warn line
      end

      raise
    end
  end
end