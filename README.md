# Version Pinning

A gem for pinning versions from Gemfile.lock to Gemfile.

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

### Structure

```
.
├── version_pinning.gemspec
├── .gitignore
└── lib
    └── version_pinning.rb
└── spec
    └── factories
        └── base_gemfile_locks.rb
    └── version_pinning_spec.rb
```

### Setting up project

1. Run `bundle install`;

### Running tests

```
bundle exec rspec
```
