require 'spec_helper'

describe Procrastinate::SpawnStrategy::Default do
  its(:limit) { should > 0 }
end