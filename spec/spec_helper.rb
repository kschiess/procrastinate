
RSpec.configure do |config|
  config.mock_with :flexmock
end

require 'timeout'
require 'tempfile'

require 'procrastinate'