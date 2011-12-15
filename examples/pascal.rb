
# Computes Pascals triangle using procrastinate. This is mainly a stress test 
# for result handling code and is NOT how I would parallelize this task!

$:.unshift File.dirname(__FILE__) + '/../lib'

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

  puts last.map { |e| sprintf("%3d", e.value) }.join(' ')
  
  current = [V.new(1)] + 
    last.each_cons(2).map { |l,r| 
      Procrastinate.schedule { l.value + r.value }
    } + 
    [V.new(1)]
end