
# Computes Pascals triangle using procrastinate. This is mainly a stress test 
# for result handling code and is NOT how I would parallelize this task!

$:.unshift File.dirname(__FILE__) + '/../lib'

trap('INFO') {  
  puts "You sent me a SIGINFO at #{Time.now}."
  Thread.list.each do |thread|
    p thread
    p thread.backtrace.first(5)
    puts
  end
}


require 'procrastinate'
require 'procrastinate/implicit'
include Procrastinate

V = Struct.new(:value) do
  def ready?; true; end
end

current = [
  V.new(1), 
  V.new(1)
]

loop do
  last = current
  Procrastinate.join 

  not_ready = current.reject { |r| r.ready? }
  puts "Not ready: #{not_ready.size}" unless not_ready.empty?

  puts last.map { |e| sprintf("%3d", e.value) }.join(' ')
  
  current = [V.new(1)] + 
    last.each_cons(2).map { |l,r| 
      l, r = [l.value, r.value]
      
      Procrastinate.schedule { l + r }
    } + 
    [V.new(1)]
end