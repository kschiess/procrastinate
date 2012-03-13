require 'spec_helper'

describe "Server mode (#spawn_workers)" do
  let(:server) { Procrastinate::Server.new }
  after(:each) { server.shutdown }
  
  let(:pipe) { Cod.pipe.split }
  after(:each) { pipe.read.close; pipe.write.close; }

  it "spawns n workers" do
    server.start(5) {
      pipe.write.put Process.pid
      sleep 10
    }
    
    collected_worker_pids = 3.times.map { pipe.read.get }.compact
    p collected_worker_pids
    collected_worker_pids.should have(3).pids_stored_in_it
  end 
end