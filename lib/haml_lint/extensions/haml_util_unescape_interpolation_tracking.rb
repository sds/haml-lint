# frozen_string_literal: true

# Haml does heavy transformations to strings that contain interpolation without a way
# of perfectly inverting that transformation.
#
# We need this monkey patch to have a way of recovering the original strings as they
# are in the haml files, so that we can use them and then autocorrect them.
#
# The HamlLint::Document carries over a hash of interpolation to original string. The
# below patches are there to extract said information from Haml's parsing.
module Haml::Util
  # The cache for the current Thread (technically Fiber)
  def self.unescape_interpolation_to_original_cache
    Thread.current[:haml_lint_unescape_interpolation_to_original_cache] ||= {}
  end

  # As soon as a HamlLint::Document has finished processing a HAML source, this gets called to
  # get a copy of this cache and clear up for the next HAML processing
  def self.unescape_interpolation_to_original_cache_take_and_wipe
    value = unescape_interpolation_to_original_cache.dup
    unescape_interpolation_to_original_cache.clear
    value
  end

  # Overriding the unescape_interpolation method to store the return and original string
  # in the cache.
  def unescape_interpolation_with_original_tracking(str, escape_html = nil)
    value = unescape_interpolation_without_original_tracking(str, escape_html)
    Haml::Util.unescape_interpolation_to_original_cache[value] = str
    value
  end

  alias unescape_interpolation_without_original_tracking unescape_interpolation
  alias unescape_interpolation unescape_interpolation_with_original_tracking
end
