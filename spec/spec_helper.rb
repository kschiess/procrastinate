
RSpec.configure do |config|
  config.mock_with :flexmock
end

require 'timeout'
require 'tempfile'

require 'procrastinate'

trap('INFO') {  
  Thread.list.each do |thread|
    p thread
    p thread.backtrace.first(5)
    puts
  end
}