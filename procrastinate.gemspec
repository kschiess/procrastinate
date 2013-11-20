# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{procrastinate}
  s.version = "0.6.0"

  s.authors = ["Kaspar Schiess", "Patrick Marchi"]
  s.email = ["kaspar.schiess@absurd.li", "mail@patrickmarchi.ch"]
  s.extra_rdoc_files = ["README"]
  s.files = %w(HISTORY.txt LICENSE README) + Dir.glob("{lib,examples}/**/*")
  s.homepage = %q{http://github.com/kschiess/procrastinate}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.summary = %q{Framework to run tasks in separate processes.}

  s.add_dependency('state_machine', '~> 1.1')
  
  s.add_development_dependency('rake')
  s.add_development_dependency('rspec')
  s.add_development_dependency('flexmock')
  s.add_development_dependency('guard')
  s.add_development_dependency('growl')
  s.add_development_dependency('yard')
end
