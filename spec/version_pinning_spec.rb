# frozen_string_literal: true

require "tempfile"
require_relative "../lib/version_pinning"

RSpec.describe VersionPinning do
  let(:dummy_class) { Class.new { extend VersionPinning } }
  let(:fixtures_path) { File.join(__dir__, "fixtures") }

  it "has a version number" do
    expect(VersionPinning::VERSION).not_to be_nil
  end

  it "lists local gems" do
    expect(dummy_class.list_gems).to include("rubocop")
    expect(dummy_class.list_gems).not_to include("sidekiq")
  end

  describe VersionPinning::LockfileParser do
    let(:lockfile_path) { File.join(fixtures_path, "sample.lock") }

    describe ".parse" do
      it "extracts gem names and versions from a lockfile" do
        versions = described_class.parse(lockfile_path)
        expect(versions).to be_a(Hash)
        expect(versions["rake"]).to eq("13.0.6")
        expect(versions["rspec"]).to eq("3.12.0")
        expect(versions["rubocop"]).to eq("1.50.2")
        expect(versions["rack"]).to eq("2.2.6")
      end

      it "includes transitive dependencies" do
        versions = described_class.parse(lockfile_path)
        expect(versions["ast"]).to eq("2.4.2")
        expect(versions["parallel"]).to eq("1.22.1")
        expect(versions["rainbow"]).to eq("3.1.1")
      end

      it "does not include gems that are not in the lockfile" do
        versions = described_class.parse(lockfile_path)
        expect(versions).not_to have_key("sidekiq")
      end
    end
  end

  describe VersionPinning::GemfilePinner do
    describe ".pin_versions" do
      let(:locked_versions) do
        {
          "rake" => "13.0.6",
          "rspec" => "3.12.0",
          "rubocop" => "1.50.2",
          "rack" => "2.2.6"
        }
      end

      it "pins versions for gems with existing version constraints" do
        content = 'gem "rake", "~> 13.0"'
        result = described_class.pin_versions(content, locked_versions)
        expect(result).to eq('gem "rake", "13.0.6"')
      end

      it "adds versions for gems without version constraints" do
        content = 'gem "rack"'
        result = described_class.pin_versions(content, locked_versions)
        expect(result).to eq('gem "rack", "2.2.6"')
      end

      it "leaves gems not in the lockfile unchanged" do
        content = 'gem "sidekiq"'
        result = described_class.pin_versions(content, locked_versions)
        expect(result).to eq('gem "sidekiq"')
      end

      it "handles single-quoted gem names" do
        content = "gem 'rake', '~> 13.0'"
        result = described_class.pin_versions(content, locked_versions)
        expect(result).to eq("gem 'rake', \"13.0.6\"")
      end

      it "preserves comments and other lines" do
        content = <<~GEMFILE
          # frozen_string_literal: true

          source "https://rubygems.org"

          gem "rake", "~> 13.0"
          gem "rack"
        GEMFILE

        result = described_class.pin_versions(content, locked_versions)
        expect(result).to include('gem "rake", "13.0.6"')
        expect(result).to include('gem "rack", "2.2.6"')
        expect(result).to include("# frozen_string_literal: true")
        expect(result).to include('source "https://rubygems.org"')
      end
    end
  end

  describe ".pin" do
    it "raises an error when Gemfile does not exist" do
      expect {
        VersionPinning.pin(gemfile_path: "nonexistent", lockfile_path: "Gemfile.lock")
      }.to raise_error(VersionPinning::Error, /Gemfile not found/)
    end

    it "raises an error when Gemfile.lock does not exist" do
      gemfile = Tempfile.new("Gemfile")
      gemfile.write('gem "rake"')
      gemfile.close

      expect {
        VersionPinning.pin(gemfile_path: gemfile.path, lockfile_path: "nonexistent")
      }.to raise_error(VersionPinning::Error, /Gemfile.lock not found/)
    ensure
      gemfile&.unlink
    end

    it "pins versions from lockfile to gemfile" do
      fixtures_path = File.join(__dir__, "fixtures")
      lockfile_path = File.join(fixtures_path, "sample.lock")

      gemfile = Tempfile.new("Gemfile")
      gemfile.write(File.read(File.join(fixtures_path, "sample_gemfile")))
      gemfile.close

      VersionPinning.pin(gemfile_path: gemfile.path, lockfile_path: lockfile_path)

      result = File.read(gemfile.path)
      expect(result).to include('gem "rake", "13.0.6"')
      expect(result).to include('gem "rspec", "3.12.0"')
      expect(result).to include('gem "rubocop", "1.50.2"')
      expect(result).to include('gem "rack", "2.2.6"')
    ensure
      gemfile&.unlink
    end
  end
end
