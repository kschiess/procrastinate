
module Procrastinate::DispatchStrategy
  # Raised when you request a shutdown and then schedule new work. 
  #
  class ShutdownRequested < StandardError; end
end

require 'procrastinate/dispatch_strategy/simple'
