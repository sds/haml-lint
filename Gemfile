source 'https://rubygems.org'

# Pin Rubocop for Travis builds.
# This won't affect people installing via `gem install` since it's not in the
# gemspec. It needs to come before the call to `gemspec` below in order to
# prevent a warning being displayed about duplicate dependencies when running
# `bundle install` in this repository.
gem 'rubocop', '0.27.1'

# Run `wwtd` to emulate Travis builds locally
gem 'wwtd'

gemspec
