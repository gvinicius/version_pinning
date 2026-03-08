# frozen_string_literal: true

require_relative "version_pinning/version"
require_relative "version_pinning/lockfile_parser"
require_relative "version_pinning/gemfile_pinner"

module VersionPinning
  class Error < StandardError; end

  def list_gems
    Gem::Specification.
      sort_by { |gem| [gem.name.downcase, gem.version] }.
      group_by(&:name)
  end

  def self.pin(gemfile_path: "Gemfile", lockfile_path: "Gemfile.lock")
    raise Error, "Gemfile not found: #{gemfile_path}" unless File.exist?(gemfile_path)
    raise Error, "Gemfile.lock not found: #{lockfile_path}" unless File.exist?(lockfile_path)

    locked_versions = LockfileParser.parse(lockfile_path)
    GemfilePinner.pin(gemfile_path, locked_versions)
  end
end
