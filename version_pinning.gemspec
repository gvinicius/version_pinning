# frozen_string_literal: true

require_relative "lib/version_pinning/version"

Gem::Specification.new do |spec|
  spec.name = "version_pinning"
  spec.version = VersionPinning::VERSION
  spec.authors = ["Vinicius Lins Gesteira"]
  spec.email = ["vlinsufba@gmail.com"]

  spec.summary = "Pin gem versions from Gemfile.lock to Gemfile"
  spec.description = "A utility gem that reads locked versions from Gemfile.lock and pins them in your Gemfile, ensuring consistent dependency versions across environments."
  spec.homepage = "https://github.com/gvinicius/version_pinning"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/gvinicius/version_pinning"
  spec.metadata["changelog_uri"] = "https://github.com/gvinicius/version_pinning/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
