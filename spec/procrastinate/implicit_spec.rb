require 'spec_helper'

require 'procrastinate/implicit'

describe "Implicit use of the scheduler", :type => :acceptance do
  class ImplicitSpecWorker
    def do_something
      'bar'
    end
  end
  
  context "when scheduling through Procrastinate module" do
    before(:each) { Procrastinate.reset }
    
    let(:proxy) { Procrastinate.proxy(ImplicitSpecWorker.new) }
    subject { proxy.do_something }
    before(:each) { subject }
    
    its(:value) { should == 'bar' }
  end
end