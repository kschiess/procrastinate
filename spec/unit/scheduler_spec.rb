
require 'spec_helper'

describe Procrastinate::Scheduler do
  attr_reader :scheduler
  before(:each) do
    @scheduler = Procrastinate::Scheduler.new
  end
end