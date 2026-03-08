# frozen_string_literal: true

module VersionPinning
  module GemfilePinner
    GEM_DECLARATION_PATTERN = /^(\s*gem\s+(['"])(\S+)\2)(.*)$/

    def self.pin(gemfile_path, locked_versions)
      content = File.read(gemfile_path)
      updated_content = pin_versions(content, locked_versions)
      File.write(gemfile_path, updated_content)
      updated_content
    end

    def self.pin_versions(content, locked_versions)
      content.gsub(GEM_DECLARATION_PATTERN) do |_match|
        prefix = Regexp.last_match(1)
        gem_name = Regexp.last_match(3)
        rest = Regexp.last_match(4)

        locked_version = locked_versions[gem_name]
        next "#{prefix}#{rest}" unless locked_version

        if rest.match?(/,\s*['"]/)
          # Replace existing version constraint
          updated_rest = rest.sub(/,\s*['"][^'"]*['"]/, ", \"#{locked_version}\"")
          "#{prefix}#{updated_rest}"
        else
          # Add version after gem name
          "#{prefix}, \"#{locked_version}\"#{rest}"
        end
      end
    end
  end
end
