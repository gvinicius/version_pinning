# frozen_string_literal: true

require_relative 'version_pinning/version'

module VersionPinning
  class Error < StandardError; end

  def list_gems
    Gem::Specification
      .sort_by { |gem| [gem.name.downcase, gem.version] }
      .group_by { |gem| gem.name }
  end
end
