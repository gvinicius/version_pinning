# frozen_string_literal: true

module VersionPinning
  module LockfileParser
    GEM_SECTION_HEADER = "GEM"
    SPECS_HEADER = "  specs:"
    GEM_LINE_PATTERN = /\A    (\S+) \((\S+)\)\z/

    def self.parse(lockfile_path)
      content = File.read(lockfile_path)
      extract_gem_versions(content)
    end

    def self.extract_gem_versions(content)
      versions = {}
      in_gem_section = false
      in_specs = false

      content.each_line do |line|
        line = line.chomp

        if line == GEM_SECTION_HEADER
          in_gem_section = true
          in_specs = false
          next
        end

        if in_gem_section && line == SPECS_HEADER
          in_specs = true
          next
        end

        if in_gem_section && in_specs
          if line.match?(GEM_LINE_PATTERN)
            match = line.match(GEM_LINE_PATTERN)
            versions[match[1]] = match[2]
          elsif !line.start_with?("      ") && line.strip != ""
            in_specs = false
            in_gem_section = false if !line.start_with?("  ")
          end
        end
      end

      versions
    end
  end
end
