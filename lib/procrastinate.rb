
module Procrastinate
  autoload :Lock,     'procrastinate/lock'
  autoload :Runtime,  'procrastinate/runtime'
  autoload :IPC,      'procrastinate/ipc'
  autoload :Task,     'procrastinate/task'
end

require 'procrastinate/spawn_strategy'
require 'procrastinate/proxy'
require 'procrastinate/process_manager'
require 'procrastinate/scheduler'