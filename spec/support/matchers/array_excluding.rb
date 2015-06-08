# Define matcher which determines if an array does NOT include any of a list of
# items.
#
# Unclear why this isn't part of the core, but it's useful.
RSpec::Matchers.define_negated_matcher :array_excluding, :include
