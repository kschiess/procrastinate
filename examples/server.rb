
$:.unshift File.dirname(__FILE__) + '/../lib'

require 'procrastinate'

# * murder lazies
# * maintain worker count

scheduler = Procrastinate::Scheduler.start
scheduler.spawn_workers(6) {
  # Worker body
  loop do
    puts "Hiho from worker #{Process.pid}."
    sleep rand(1.0) * 3
  end
}

# Wait around until something important happens
r, w = IO.pipe
trap('QUIT') { w.write '.' }

loop do
  IO.select([r], nil, nil)
  r.read_nonblock(1000)
  
  # When we reach this point, a QUIT signal has been sent to the process. 
  # Abort.
  break
end

scheduler.shutdown