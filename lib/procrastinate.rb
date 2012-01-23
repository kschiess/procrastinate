
module Procrastinate
  # Raised when you try to access a future value that belongs to a process
  # that died before producing a value. 
  #
  class ChildDeath < StandardError; end
  
  autoload :Lock,     'procrastinate/lock'
  autoload :Runtime,  'procrastinate/runtime'
  autoload :Task,     'procrastinate/task'
end

require 'procrastinate/spawn_strategy'
require 'procrastinate/proxy'
require 'procrastinate/process_manager'
require 'procrastinate/scheduler'