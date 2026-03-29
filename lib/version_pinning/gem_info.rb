# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module VersionPinning
  # Fetches and displays gem verification metadata from RubyGems.org.
  #
  # Inspired by the RubyGems.org gem profile page initiative, based on
  # feedback from Andrea Fomera and Marco Roth — surfacing the info
  # developers need to verify a gem before adding it to their project.
  module GemInfo
    RUBYGEMS_API_URL = "https://rubygems.org/api/v1/gems/%<name>s.json"
    RUBYGEMS_VERSIONS_URL = "https://rubygems.org/api/v1/versions/%<name>s.json"
    RUBYGEMS_OWNERS_URL = "https://rubygems.org/api/v1/owners/%<name>s.json"
    RUBYGEMS_REVERSE_DEPS_URL = "https://rubygems.org/api/v1/gems/%<name>s/reverse_dependencies.json"

    class << self
      def fetch(gem_name)
        data = fetch_gem_data(gem_name)
        return nil if data.nil?

        {
          name: data["name"],
          version: data["version"],
          authors: data["authors"],
          licenses: data["licenses"],
          summary: data["info"],
          homepage: data["homepage_uri"],
          source_code: data["source_code_uri"],
          changelog: data["changelog_uri"],
          documentation: data["documentation_uri"],
          bug_tracker: data["bug_tracker_uri"],
          mailing_list: data["mailing_list_uri"],
          wiki: data["wiki_uri"],
          downloads: data["downloads"],
          version_downloads: data["version_downloads"],
          created_at: data["created_at"],
          dependencies: extract_dependencies(data),
          metadata: data["metadata"] || {}
        }
      end

      def display(gem_name)
        info = fetch(gem_name)
        raise Error, "Gem not found: #{gem_name}" if info.nil?

        format_display(info)
      end

      def verify(gem_name)
        info = fetch(gem_name)
        raise Error, "Gem not found: #{gem_name}" if info.nil?

        checks = run_checks(info)
        format_verification(info, checks)
      end

      private

      def fetch_gem_data(gem_name)
        uri = URI(format(RUBYGEMS_API_URL, name: gem_name))
        response = Net::HTTP.get_response(uri)
        return nil unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)
      end

      def extract_dependencies(data)
        deps = { runtime: [], development: [] }
        if data["dependencies"]
          (data["dependencies"]["runtime"] || []).each do |dep|
            deps[:runtime] << { name: dep["name"], requirements: dep["requirements"] }
          end
          (data["dependencies"]["development"] || []).each do |dep|
            deps[:development] << { name: dep["name"], requirements: dep["requirements"] }
          end
        end
        deps
      end

      def run_checks(info)
        {
          has_source_code: !info[:source_code].nil? && !info[:source_code].empty?,
          has_changelog: !info[:changelog].nil? && !info[:changelog].empty?,
          has_documentation: !info[:documentation].nil? && !info[:documentation].empty?,
          has_homepage: !info[:homepage].nil? && !info[:homepage].empty?,
          has_license: !info[:licenses].nil? && info[:licenses].any?,
          has_bug_tracker: !info[:bug_tracker].nil? && !info[:bug_tracker].empty?,
          low_dependencies: info[:dependencies][:runtime].size <= 5,
          established: info[:downloads].to_i > 1000
        }
      end

      def format_display(info)
        lines = []
        lines << "#{info[:name]} (#{info[:version]})"
        lines << "=" * lines.first.length
        lines << ""
        lines << info[:summary] if info[:summary]
        lines << ""
        lines << "Author(s):      #{info[:authors]}" if info[:authors]
        lines << "License(s):     #{Array(info[:licenses]).join(', ')}" if info[:licenses]&.any?
        lines << "Downloads:      #{format_number(info[:downloads])}" if info[:downloads]
        lines << "Created:        #{info[:created_at]&.split('T')&.first}" if info[:created_at]
        lines << ""
        lines << "Links:"
        lines << "  Homepage:      #{info[:homepage]}" if info[:homepage] && !info[:homepage].empty?
        lines << "  Source code:   #{info[:source_code]}" if info[:source_code] && !info[:source_code].empty?
        lines << "  Changelog:     #{info[:changelog]}" if info[:changelog] && !info[:changelog].empty?
        lines << "  Documentation: #{info[:documentation]}" if info[:documentation] && !info[:documentation].empty?
        lines << "  Bug tracker:   #{info[:bug_tracker]}" if info[:bug_tracker] && !info[:bug_tracker].empty?

        if info[:dependencies][:runtime].any?
          lines << ""
          lines << "Runtime dependencies (#{info[:dependencies][:runtime].size}):"
          info[:dependencies][:runtime].each do |dep|
            lines << "  #{dep[:name]} #{dep[:requirements]}"
          end
        end

        lines.join("\n")
      end

      def format_verification(info, checks)
        lines = []
        lines << "Verification: #{info[:name]} (#{info[:version]})"
        lines << "=" * lines.first.length
        lines << ""
        lines << "#{check_icon(checks[:has_source_code])} Source code link"
        lines << "#{check_icon(checks[:has_changelog])} Changelog link"
        lines << "#{check_icon(checks[:has_documentation])} Documentation link"
        lines << "#{check_icon(checks[:has_homepage])} Homepage link"
        lines << "#{check_icon(checks[:has_license])} License declared"
        lines << "#{check_icon(checks[:has_bug_tracker])} Bug tracker link"
        lines << "#{check_icon(checks[:low_dependencies])} Low dependency count (<= 5 runtime deps)"
        lines << "#{check_icon(checks[:established])} Established (> 1,000 downloads)"
        lines << ""

        passed = checks.values.count(true)
        total = checks.size
        lines << "Score: #{passed}/#{total}"

        lines.join("\n")
      end

      def check_icon(passed)
        passed ? "[PASS]" : "[FAIL]"
      end

      def format_number(num)
        num.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')
      end
    end
  end
end
