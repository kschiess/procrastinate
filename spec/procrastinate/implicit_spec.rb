require 'spec_helper'

require 'procrastinate/implicit'

describe "Implicit use of the scheduler", :type => :acceptance do
  class ImplicitSpecWorker
    def do_something
      'bar'
    end
  end
  
  context "when scheduling through Procrastinate module" do
    let(:proxy) { Procrastinate.proxy(ImplicitSpecWorker.new) }
    subject { proxy.do_something }
    
    its(:value) { should == 'bar' }
    
    # Normally, the user would not do this. We do it here because our tests
    # need isolation. 
    after(:each) { Procrastinate.shutdown }
  end
end