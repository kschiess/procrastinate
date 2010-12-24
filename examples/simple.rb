
$:.unshift File.dirname(__FILE__) + '/../lib'

require 'procrastinate'

class Worker
  def do_work
    puts "> Starting work in process #{Process.pid}"
    sleep 10
    puts "< Work completed in process #{Process.pid}"
  end
end

scheduler = Procrastinate::Scheduler.start
worker = scheduler.proxy(Worker.new)

10.times do 
  worker.do_work
end

scheduler.shutdown
