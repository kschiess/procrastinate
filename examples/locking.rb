
$:.unshift File.dirname(__FILE__) + '/../lib'

require 'procrastinate'

class Worker < Struct.new(:runtime)
  def do_work
    puts "#{Process.pid}: starting..."
    runtime.lock('lock') do
      puts "#{Process.pid}: holds lock"
      sleep 0.1
      puts "#{Process.pid}: releases"
    end
    puts "#{Process.pid}: done."
  end
end

Procrastinate::Lock.base = '/tmp'   # This will have to be moved into scheduler
scheduler = Procrastinate::Scheduler.start
worker = scheduler.proxy(Worker.new(scheduler.runtime))

10.times do 
  worker.do_work
end

scheduler.shutdown
