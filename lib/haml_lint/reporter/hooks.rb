# frozen_string_literal: true

module HamlLint
  class Reporter
    # A collection of hook methods for incremental processing.
    module Hooks
      # A hook that is called for each lint as it is detected.
      #
      # @param _lint [HamlLint::Lint] the lint added to the report
      # @param _report [HamlLint::Report] the report that contains the lint
      # @return [void]
      def added_lint(_lint, _report); end

      # A hook that is called for each file as it is finished processing.
      #
      # @param _file [String] the name of the file that just finished
      # @param _lints [Array<HamlLint::Lint>] the lints added to the report
      # @return [void]
      def finished_file(_file, _lints); end

      # A hook that is called when the processing starts.
      #
      # @param _files [Array<String>] the names of the files to be processed
      # @return [void]
      def start(_files); end
    end
  end
end
