module IndentNormalizer
  # Strips off excess leading indentation from each line so we can use Heredocs
  # for writing code without having the leading indentation count.
  def normalize_indent(code)
    leading_indent = code.match(/^(\s*)/)[1]
    code.strip.gsub(/\n#{leading_indent}/, "\n")
  end
end

RSpec.configure do |config|
  include IndentNormalizer
end
