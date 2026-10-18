# frozen_string_literal: true

require_relative "lib/administratum/version"

Gem::Specification.new do |spec|
  spec.name        = "administratum"
  spec.version     = Administratum::VERSION
  spec.authors     = ["buffpojken"]
  spec.email       = ["daniel@monkeydancers.com"]
  spec.summary     = "A file-per-resource admin engine for Rails with a DSL, template overrides and JS islands."
  spec.description = "Declare adminable resources in app/admin, get a Tailwind v4 CRUD UI with Devise login, " \
                     "custom fields, nested resources, custom actions and framework-agnostic JS islands."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2"

  # Private gem: `rake release` pushes here instead of rubygems.org. See rakelib/codeartifact.rake.
  spec.metadata["allowed_push_host"] = "https://greyseal-791515923336.d.codeartifact.eu-north-1.amazonaws.com/ruby/gems/"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md", "DESIGN.md"]
  end

  spec.add_dependency "csv"
  spec.add_dependency "devise", ">= 4.9"
  spec.add_dependency "pagy", ">= 9.0", "< 10"
  spec.add_dependency "rails", ">= 8.0"
  spec.add_dependency "ransack", ">= 4.0"
end
