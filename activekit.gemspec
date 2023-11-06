require_relative "lib/active_kit/version"

Gem::Specification.new do |spec|
  spec.name        = "activekit"
  spec.version     = ActiveKit::VERSION
  spec.authors     = ["plainsource"]
  spec.email       = ["plainsource@timeboard.org"]
  spec.homepage    = "https://github.com/plainsource/activekit"
  spec.summary     = "Add useful features to ActiveRecord"
  spec.description = "Add the essential kit for rails ActiveRecord models and be happy."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.1.3", ">= 6.1.3.1"
end
