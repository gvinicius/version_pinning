# Version Pinning

A gem for pinning versions from Gemfile.lock to Gemfile, and verifying gem metadata before adding new dependencies.

### Prerequisites

- Ruby 3.2
- Bundler 2.6.1

### Installing this gem

```
gem install 'version_pinning'
```
or
```
bundle add 'version_pinning'
```

### Usage

#### Pin versions from Gemfile.lock to Gemfile

```ruby
require "version_pinning"

# Pin all gem versions using default paths (Gemfile + Gemfile.lock)
VersionPinning.pin

# Or specify custom paths
VersionPinning.pin(gemfile_path: "Gemfile", lockfile_path: "Gemfile.lock")
```

This replaces flexible version constraints (e.g. `~> 13.0`) with exact locked versions (e.g. `13.0.6`), and adds version pins to gems that have none.

#### Verify a gem before adding it

When thinking of adding a new gem, there's a lot of info you need to look through to verify it. The `GemInfo` module fetches metadata from RubyGems.org and runs verification checks so you can evaluate a gem at a glance:

```ruby
# Display gem profile info
puts VersionPinning::GemInfo.display("rake")
# => rake (13.0.6)
# => ==================
# => Author(s):      Hiroshi SHIBATA, Eric Hodel, Jim Weirich
# => License(s):     MIT
# => Downloads:      500,000,000
# => Links:
# =>   Source code:   https://github.com/ruby/rake
# =>   Changelog:     ...
# =>   Documentation: ...

# Run verification checks
puts VersionPinning::GemInfo.verify("rake")
# => [PASS] Source code link
# => [PASS] Changelog link
# => [PASS] Documentation link
# => [PASS] Homepage link
# => [PASS] License declared
# => [PASS] Bug tracker link
# => [PASS] Low dependency count (<= 5 runtime deps)
# => [PASS] Established (> 1,000 downloads)
# => Score: 8/8

# Fetch raw metadata hash
info = VersionPinning::GemInfo.fetch("rake")
info[:source_code]   # => "https://github.com/ruby/rake"
info[:licenses]      # => ["MIT"]
info[:dependencies]  # => { runtime: [...], development: [...] }
```

The verification checks help surface the "harness" of a gem — source code, changelog, documentation, license, bug tracker, dependency count, and download traction — in a way that a GitHub README alone can't.

### Structure

```
.
├── version_pinning.gemspec
├── .gitignore
└── lib
    └── version_pinning.rb
    └── version_pinning/
        ├── version.rb
        ├── lockfile_parser.rb
        ├── gemfile_pinner.rb
        └── gem_info.rb
└── spec
    └── version_pinning_spec.rb
    └── gem_info_spec.rb
    └── fixtures/
        ├── sample.lock
        └── sample_gemfile
```

### Setting up project

1. Run `bundle install`

### Running tests

```
bundle exec rspec
```

### Acknowledgments

The gem verification feature was inspired by the RubyGems.org gem profile page initiative and community discussion around what developers need to see when evaluating a new dependency. Special thanks to:

- **[Andrea Fomera](https://github.com/shortcutsync)** — for feedback on what info matters most when verifying gems
- **[Marco Roth](https://github.com/marcoroth)** — for feedback and for building [gem.sh](https://github.com/marcoroth/gem.sh), a documentation hub that shows the kind of gem profile info that a GitHub README can't

Ideally, a gem's profile page should be a page you'd feel proud to post. This feature aims to make it easy to check whether a gem meets that bar.
