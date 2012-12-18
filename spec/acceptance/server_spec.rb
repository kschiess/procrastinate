require 'spec_helper'

describe "Server mode (#spawn_workers)" do
  let(:server) { Procrastinate::Server.new }
  after(:each) { server.shutdown }
  
  let(:pipe) { Cod.pipe.split }
  after(:each) { pipe.read.close; pipe.write.close; }
  let(:n) { 5 }
  
  def read_tokens(n)
    n.times.map { pipe.read.get }
  end

  it "spawns n workers" do
    server.start(n) {
      pipe.write.put Process.pid
      sleep 10
    }
    
    collected_worker_pids = n.times.map { pipe.read.get }.compact
    collected_worker_pids.should have(n).pids_stored_in_it
  end 
  it "respawns workers until there are n workers again" do
    server.start(n) {
      pipe.write.put Process.pid
      sleep 10
    }
    
    pids = read_tokens(n)
    
    # Now kill a few pids: 
    pids[0,2].each { |pid| Process.kill('QUIT', pid) }
    
    new_pids = read_tokens(2)
    new_pids.should have(2).pids_stored
    (new_pids & pids).should == []
  end 
  it "checks activity around the loop, killing processes if they are lazy" do
    server.start(n, 0.1) { |dead_man_switch| 
      pipe.write.put Process.pid
      loop do
        sleep 0.1
      end }
      
    # There should be a steady stream of process pids coming in, since they
    # are all killed after 0.1 seconds of inactivity. After 0.2 seconds, 
    # we should roughly read 2*n pids.
    pids = []
    begin
      timeout(0.2) { loop { pids << pipe.read.get } }
    rescue Timeout::Error
    end
    
    pids.size.should >= n
  end 
end