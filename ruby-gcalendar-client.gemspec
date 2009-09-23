# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{gcalcliapp}
  s.version = "0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Miguel Baldi"]
  s.date = %q{2009-09-23}
  s.description = %q{GCalCli is a client for Google Calendar service.}
  s.email = %q{miguel.horlle@gmailcom}
  s.extra_rdoc_files = ["README", "LICENSE"]
  s.files = ["README", "VERSION.yml", "gcalcliapp", "lib/gcalcore.rb", "LICENSE"]
  s.has_rdoc = false 
  s.homepage = %q{http://github.com/miguelbaldi/ruby-gcalendar-client}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.0}
  s.summary = %q{GCalCli is a client for Google Calendar service.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<simpleconsole>, [">= 0.1.1"])
      s.add_runtime_dependency(%q<ri_cal>, [">= 0.8.4"])
      s.add_runtime_dependency(%q<tzinfo>, [">= 0.3.13"])
    else
      s.add_dependency(%q<simpleconsole>, [">= 0.1.1"])
      s.add_dependency(%q<ri_cal>, [">= 0.8.4"])
      s.add_dependency(%q<tzinfo>, [">= 0.3.13"])
    end
  else
    s.add_dependency(%q<simpleconsole>, [">= 0.1.1"])
    s.add_dependency(%q<ri_cal>, [">= 0.8.4"])
    s.add_dependency(%q<tzinfo>, [">= 0.3.13"])
  end
end
