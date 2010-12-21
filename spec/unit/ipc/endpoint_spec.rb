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
end