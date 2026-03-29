# frozen_string_literal: true

require "spec_helper"
require "json"
require "net/http"

RSpec.describe VersionPinning::GemInfo do
  let(:sample_api_response) do
    {
      "name" => "rake",
      "version" => "13.0.6",
      "authors" => "Hiroshi SHIBATA, Eric Hodel, Jim Weirich",
      "licenses" => ["MIT"],
      "info" => "Rake is a Make-like program implemented in Ruby.",
      "homepage_uri" => "https://github.com/ruby/rake",
      "source_code_uri" => "https://github.com/ruby/rake",
      "changelog_uri" => "https://github.com/ruby/rake/blob/v13.0.6/History.rdoc",
      "documentation_uri" => "https://ruby.github.io/rake",
      "bug_tracker_uri" => "https://github.com/ruby/rake/issues",
      "mailing_list_uri" => nil,
      "wiki_uri" => nil,
      "downloads" => 500_000_000,
      "version_downloads" => 100_000_000,
      "created_at" => "2009-03-18T05:24:18.000Z",
      "metadata" => { "changelog_uri" => "https://github.com/ruby/rake/blob/v13.0.6/History.rdoc" },
      "dependencies" => {
        "runtime" => [],
        "development" => [
          { "name" => "bundler", "requirements" => ">= 0" }
        ]
      }
    }
  end

  let(:minimal_api_response) do
    {
      "name" => "obscure_gem",
      "version" => "0.0.1",
      "authors" => "Unknown",
      "licenses" => [],
      "info" => "A minimal gem",
      "homepage_uri" => "",
      "source_code_uri" => "",
      "changelog_uri" => nil,
      "documentation_uri" => nil,
      "bug_tracker_uri" => nil,
      "mailing_list_uri" => nil,
      "wiki_uri" => nil,
      "downloads" => 50,
      "version_downloads" => 10,
      "created_at" => "2025-01-01T00:00:00.000Z",
      "metadata" => {},
      "dependencies" => {
        "runtime" => [
          { "name" => "dep1", "requirements" => ">= 1.0" },
          { "name" => "dep2", "requirements" => ">= 2.0" },
          { "name" => "dep3", "requirements" => ">= 0" },
          { "name" => "dep4", "requirements" => ">= 0" },
          { "name" => "dep5", "requirements" => ">= 0" },
          { "name" => "dep6", "requirements" => ">= 0" }
        ],
        "development" => []
      }
    }
  end

  def stub_gem_api(gem_name, response_body, status: 200)
    uri = URI("https://rubygems.org/api/v1/gems/#{gem_name}.json")
    http_response = instance_double(Net::HTTPSuccess, body: JSON.generate(response_body))
    allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(status == 200)
    allow(Net::HTTP).to receive(:get_response).with(uri).and_return(http_response)
  end

  def stub_gem_api_not_found(gem_name)
    uri = URI("https://rubygems.org/api/v1/gems/#{gem_name}.json")
    http_response = instance_double(Net::HTTPNotFound)
    allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
    allow(Net::HTTP).to receive(:get_response).with(uri).and_return(http_response)
  end

  describe ".fetch" do
    it "returns gem metadata as a hash" do
      stub_gem_api("rake", sample_api_response)
      info = described_class.fetch("rake")

      expect(info[:name]).to eq("rake")
      expect(info[:version]).to eq("13.0.6")
      expect(info[:authors]).to eq("Hiroshi SHIBATA, Eric Hodel, Jim Weirich")
      expect(info[:licenses]).to eq(["MIT"])
      expect(info[:source_code]).to eq("https://github.com/ruby/rake")
      expect(info[:changelog]).to eq("https://github.com/ruby/rake/blob/v13.0.6/History.rdoc")
      expect(info[:downloads]).to eq(500_000_000)
    end

    it "extracts runtime and development dependencies" do
      stub_gem_api("rake", sample_api_response)
      info = described_class.fetch("rake")

      expect(info[:dependencies][:runtime]).to be_empty
      expect(info[:dependencies][:development].size).to eq(1)
      expect(info[:dependencies][:development].first[:name]).to eq("bundler")
    end

    it "returns nil for a gem that does not exist" do
      stub_gem_api_not_found("nonexistent_gem_xyz")
      expect(described_class.fetch("nonexistent_gem_xyz")).to be_nil
    end
  end

  describe ".display" do
    it "returns a formatted string with gem info" do
      stub_gem_api("rake", sample_api_response)
      output = described_class.display("rake")

      expect(output).to include("rake (13.0.6)")
      expect(output).to include("Hiroshi SHIBATA")
      expect(output).to include("MIT")
      expect(output).to include("https://github.com/ruby/rake")
      expect(output).to include("500,000,000")
    end

    it "raises an error for unknown gems" do
      stub_gem_api_not_found("nonexistent_gem_xyz")
      expect { described_class.display("nonexistent_gem_xyz") }.to raise_error(
        VersionPinning::Error, "Gem not found: nonexistent_gem_xyz"
      )
    end
  end

  describe ".verify" do
    it "passes all checks for a well-maintained gem" do
      stub_gem_api("rake", sample_api_response)
      output = described_class.verify("rake")

      expect(output).to include("[PASS] Source code link")
      expect(output).to include("[PASS] Changelog link")
      expect(output).to include("[PASS] Documentation link")
      expect(output).to include("[PASS] Homepage link")
      expect(output).to include("[PASS] License declared")
      expect(output).to include("[PASS] Bug tracker link")
      expect(output).to include("[PASS] Low dependency count")
      expect(output).to include("[PASS] Established")
      expect(output).to include("Score: 8/8")
    end

    it "fails checks for a minimal gem" do
      stub_gem_api("obscure_gem", minimal_api_response)
      output = described_class.verify("obscure_gem")

      expect(output).to include("[FAIL] Source code link")
      expect(output).to include("[FAIL] Changelog link")
      expect(output).to include("[FAIL] Documentation link")
      expect(output).to include("[FAIL] License declared")
      expect(output).to include("[FAIL] Bug tracker link")
      expect(output).to include("[FAIL] Low dependency count")
      expect(output).to include("[FAIL] Established")
      expect(output).to include("Score: 0/8")
    end

    it "raises an error for unknown gems" do
      stub_gem_api_not_found("nonexistent_gem_xyz")
      expect { described_class.verify("nonexistent_gem_xyz") }.to raise_error(
        VersionPinning::Error, "Gem not found: nonexistent_gem_xyz"
      )
    end
  end
end
