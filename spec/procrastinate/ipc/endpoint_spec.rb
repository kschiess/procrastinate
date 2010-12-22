require 'spec_helper'

describe Procrastinate::IPC::Endpoint do
  Endpoint = Procrastinate::IPC::Endpoint
  
  # Eventually, this API might look like this: 
  # 
  # Endpoint.anonymous.server
  # Endpoint.pipe('/foo/bar').server
  # Endpoint.tcp('*:5555').client
  # Endpoint.beanstalk('beanstalkd:11300').server
  #
  # But right now, I only need the first example (server/client)
  #
  let(:anonymous) { Endpoint.anonymous }
  let(:server) { anonymous.server }
  let(:client) { anonymous.client }
  
  context "when 'foobar' has been written" do
    before(:each) { client.send('foobar') }
    subject { server.receive }
    it { should == 'foobar' }
    
    context "when another message is waiting" do
      before(:each) { client.send('foobaz') }

      subject { server.receive }
      it { should == 'foobar' }
    end
  end
  
  describe "<- #select([read])" do
    it "should return nil if a timeout occurs" do
      Endpoint.select([], 0.1)
    end 
    it "should return selectors that are ready" do
      other = Endpoint.anonymous
      client.send 'message'
      
      result = Endpoint.select([other.server, server], 0.1)
      result.should have(1).parts
      result.should include(server)
    end
    it "should allow mixed selectors (Unix and Endpoint ones)" do
      r, w = IO.pipe
      w.write('foo')
      
      result = Endpoint.select([r, server], 0.1)
      result.should have(1).parts
      result.should include(r)
    end 
    context "when messages are waiting" do
      before(:each) { 
        client.send "A"
        client.send "B"
        server.receive
      }
      it "should immediately return that endpoint" do
        other = Endpoint.anonymous
        Endpoint.select([server, other.server], 0.1).should include(server)
      end
    end
  end
end