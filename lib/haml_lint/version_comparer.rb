# frozen_string_literal: true

module HamlLint
  # A simple wrapper around Gem::Version to allow comparison with String instances
  # This makes code shorter in some places
  class VersionComparer
    def initialize(version)
      @version = Gem::Version.new(version)
    end

    include Comparable
    def <=>(other)
      @version <=> Gem::Version.new(other)
    end

    # Shortcut to create a version comparer for the current RuboCop's version
    def self.for_rubocop
      new(RuboCop::Version::STRING)
    end

    def self.for_haml
      new(Haml::VERSION)
    end
  end
end
