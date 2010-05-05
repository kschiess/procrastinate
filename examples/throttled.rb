
$:.unshift File.dirname(__FILE__) + '/../lib'

require 'procrastinate'
include Procrastinate

class Worker
  def do_work
    puts "> Starting work in process #{Process.pid}"
    sleep 2
    puts "< Work completed in process #{Process.pid}"
  end
end

scheduler = Scheduler.start(DispatchStrategy::Throttled.new(5))
worker = scheduler.create_proxy(Worker.new)

10.times do 
  worker.do_work
end

scheduler.shutdown
