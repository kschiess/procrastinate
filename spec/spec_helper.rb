
RSpec.configure do |config|
  config.mock_with :flexmock
  
  config.before(:each) { Procrastinate.reset }
end

require 'timeout'
require 'tempfile'

require 'procrastinate'