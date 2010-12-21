require 'spec_helper'

describe Procrastinate::IPC::Endpoint do
  # Eventually, this API might look like this: 
  # 
  # Endpoint.anonymous.server
  # Endpoint.pipe('/foo/bar').server
  # Endpoint.tcp('*:5555').client
  # Endpoint.beanstalk('beanstalkd:11300').server
  #
  # But right now, I only need the first example (server/client)
  #
  let(:anonymous) { Procrastinate::IPC::Endpoint.anonymous }
  let(:server) { anonymous.server }
  let(:client) { anonymous.client }
  
  context "when 'foobar' has been written" do
    before(:each) { client.send('foobar') }
    subject { server.receive }
    it { should == 'foobar' }
  end
  
  describe "<- #select([read])" do
    it "should return selectors that are ready" do
      other = Procrastinate::IPC::Endpoint.anonymous
      client.send 'message'
      
      result = Endpoint.select([other.server, server])
      result.should have(3).parts
      result.first.should include(server)
    end
    it "should allow mixed selectors (Unix and Endpoint ones)" do
      r, w = IO.pipe
      w.write('foo')
      
      result = Endpoint.select([r, server])
      result.should have(3).parts
      result.first.should include(r)
    end 
  end
end