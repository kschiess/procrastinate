# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{procrastinate}
  s.version = "0.4.0"

  s.authors = ["Kaspar Schiess", "Patrick Marchi"]
  s.email = ["kaspar.schiess@absurd.li", "mail@patrickmarchi.ch"]
  s.extra_rdoc_files = ["README"]
  s.files = %w(HISTORY.txt LICENSE Rakefile README) + Dir.glob("{lib,examples}/**/*")
  s.homepage = %q{http://github.com/kschiess/procrastinate}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.summary = %q{Framework to run tasks in separate processes.}

  s.add_runtime_dependency(%q<state_machine>, ["~> 0.9.4"])
  s.add_development_dependency(%q<rspec>, [">= 0"])
  s.add_development_dependency(%q<flexmock>, [">= 0"])
end
