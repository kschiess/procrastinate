
module Procrastinate
  autoload :Lock,     'procrastinate/lock'
  autoload :Runtime,  'procrastinate/runtime'
  autoload :IPC,      'procrastinate/ipc'
end

require 'procrastinate/spawn_strategy'
require 'procrastinate/tasks'
require 'procrastinate/proxy'
require 'procrastinate/dispatcher'
require 'procrastinate/scheduler'