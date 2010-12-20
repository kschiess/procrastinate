# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{procrastinate}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kaspar Schiess", "Patrick Marchi"]
  s.date = %q{2010-12-20}
  s.email = ["kaspar.schiess@absurd.li", "mail@patrickmarchi.ch"]
  s.extra_rdoc_files = ["README"]
  s.files = ["LICENSE", "Rakefile", "README", "spec", "lib/procrastinate", "lib/procrastinate/dispatch_strategies.rb", "lib/procrastinate/dispatch_strategy", "lib/procrastinate/dispatch_strategy/simple.rb", "lib/procrastinate/dispatch_strategy/throttled.rb", "lib/procrastinate/dispatcher.rb", "lib/procrastinate/lock.rb", "lib/procrastinate/proxy.rb", "lib/procrastinate/runtime.rb", "lib/procrastinate/scheduler.rb", "lib/procrastinate/tasks.rb", "lib/procrastinate.rb"]
  s.homepage = %q{http://github.com/kschiess/procrastinate}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Framework to run tasks in separate processes.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<flexmock>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<flexmock>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<flexmock>, [">= 0"])
  end
end
