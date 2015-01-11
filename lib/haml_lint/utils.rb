require 'find'

module HamlLint
  # A miscellaneous set of utility functions.
  module Utils
    module_function

    def extract_files_from(list)
      files = []

      list.each do |file|
        begin
          Find.find(file) do |f|
            files << f if haml_file?(f)
          end
        rescue Errno::ENOENT
          # File didn't exist; it might be a file glob pattern
          matches = Dir.glob(file)
          if matches.any?
            files += matches
          else
            # One of the paths specified does not exist; raise a more
            # descriptive exception so we know which one
            raise HamlLint::Exceptions::InvalidFilePath,
                  "File path '#{file}' does not exist"
          end
        end
      end

      files.uniq
    end

    # Yields interpolated values within a block of filter text.
    def extract_interpolated_values(filter_text)
      Haml::Util.handle_interpolation(filter_text.dump) do |scan|
        escape_count = (scan[2].size - 1) / 2
        return unless escape_count.even?

        dumped_interpolated_str = Haml::Util.balance(scan, '{', '}', 1)[0][0...-1]

        # Hacky way to turn a dumped string back into a regular string
        yield eval('"' + dumped_interpolated_str + '"') # rubocop:disable Eval
      end
    end

    # Converts a string containing underscores/hyphens/spaces into CamelCase.
    def camel_case(str)
      str.split(/_|-| /).map { |part| part.sub(/^\w/) { |c| c.upcase } }.join
    end

    # Find all consecutive nodes satisfying the given {Proc} of a minimum size
    # and yield each group.
    #
    # @param items [Array]
    # @param min_size [Fixnum] minimum number of consecutive items before
    #   yielding
    # @param satisfies [Proc] function that takes an item and returns true/false
    def find_consecutive(items, min_size, satisfies)
      current = -1

      while (current += 1) < items.count
        next unless satisfies[items[current]]

        count = count_consecutive(items, current, satisfies)
        next unless count >= min_size

        # Yield the chunk of consecutive items
        yield items[current...(current + count)]

        current += count # Skip this patch of consecutive items to find more
      end
    end

    # Count the number of consecutive items satisfying the given {Proc}.
    #
    # @param items [Array]
    # @param offset [Fixnum] index to start searching
    # @param satisfies [Proc] function to evaluate item with
    def count_consecutive(items, offset, satisfies)
      count = 1
      count += 1 while (offset + count < items.count) && satisfies[items[offset + count]]
      count
    end

    def haml_file?(file)
      return false unless FileTest.file?(file)

      File.extname(file) == '.haml'
    end
  end
end
