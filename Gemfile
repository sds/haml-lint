source 'https://rubygems.org'

gemspec

# Need this for `bundle exec` to work in Overcommit runs in Travis
gem 'bundler'

# Run all pre-commit hooks via Overcommit during CI runs
gem 'overcommit', '0.22.0'

# Pin tool versions (which are executed by Overcommit) for Travis builds
gem 'rubocop', '0.29.1'
gem 'travis', '~> 1.7'

# Run `wwtd` to emulate Travis builds locally
gem 'wwtd'
