source 'https://rubygems.org'

gemspec

gem 'rspec', '~> 3.0'
gem 'rspec-its', '~> 1.0'

# Run all pre-commit hooks via Overcommit during CI runs
gem 'overcommit', '0.36.0'

# Pin tool versions (which are executed by Overcommit) for Travis builds
gem 'rubocop', '0.42.0'
gem 'travis', '~> 1.7'
# As long as this gem supports Ruby 2.0 (and has Travis builds for Ruby 2.0),
# this line is needed. net-http-persistent >= 3.0 requires Ruby >= 2.1.
# Once haml_lint requires Ruby >= 2.1, this line can be removed altogether
# (as net-http-persistent is a dependency of gh, which is a dependency of
# travis).
gem 'net-http-persistent', '2.9.4'

gem 'coveralls', require: false
