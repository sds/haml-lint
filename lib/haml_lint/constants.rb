# frozen_string_literal: true

# Global application constants.
module HamlLint
  HOME = File.expand_path(File.join(File.dirname(__FILE__), '..', '..')).freeze
  APP_NAME = 'haml-lint'

  REPO_URL = 'https://github.com/sds/haml-lint'
  BUG_REPORT_URL = "#{REPO_URL}/issues".freeze
end
