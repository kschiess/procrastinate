# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{procrastinate}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kaspar Schiess", "Patrick Marchi"]
  s.date = %q{2010-12-22}
  s.email = ["kaspar.schiess@absurd.li", "mail@patrickmarchi.ch"]
  s.extra_rdoc_files = ["README"]
  s.files = ["LICENSE", "Rakefile", "README", "spec", "lib/procrastinate", "lib/procrastinate/ipc", "lib/procrastinate/ipc/endpoint.rb", "lib/procrastinate/ipc.rb", "lib/procrastinate/lock.rb", "lib/procrastinate/process_manager.rb", "lib/procrastinate/proxy.rb", "lib/procrastinate/runtime.rb", "lib/procrastinate/scheduler.rb", "lib/procrastinate/spawn_strategy", "lib/procrastinate/spawn_strategy/simple.rb", "lib/procrastinate/spawn_strategy/throttled.rb", "lib/procrastinate/spawn_strategy.rb", "lib/procrastinate/task", "lib/procrastinate/task/method_call.rb", "lib/procrastinate/task/result.rb", "lib/procrastinate/task.rb", "lib/procrastinate.rb"]
  s.homepage = %q{http://github.com/kschiess/procrastinate}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Framework to run tasks in separate processes.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<state_machine>, ["~> 0.9.4"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<flexmock>, [">= 0"])
    else
      s.add_dependency(%q<state_machine>, ["~> 0.9.4"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<flexmock>, [">= 0"])
    end
  else
    s.add_dependency(%q<state_machine>, ["~> 0.9.4"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<flexmock>, [">= 0"])
  end
end
