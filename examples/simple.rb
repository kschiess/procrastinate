
$:.unshift File.dirname(__FILE__) + '/../lib'

require 'procrastinate/implicit'

class Worker
  def do_work
    puts "> Starting work in process #{Process.pid}"
    sleep 2
    puts "< Work completed in process #{Process.pid}"
  end
end

worker = Procrastinate.proxy(Worker.new)

10.times do 
  worker.do_work
end

Procrastinate.join