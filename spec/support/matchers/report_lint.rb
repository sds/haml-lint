RSpec::Matchers.define :report_lint do |options|
  options ||= {}
  count = options[:count]
  expected_line = options[:line]
  expected_message = options[:message]

  match do |linter|
    has_lints?(linter, expected_line, count, expected_message)
  end

  failure_message do |linter|
    'expected that a lint would be reported' +
      extended_expectations(expected_line, expected_message) +
      case linter.lints.count
      when 0
        ''
      when 1
        messages = [', but']
        messages << "reported message '#{linter.lints.first.message}'" if expected_message
        if expected_line
          messages << 'was' unless expected_message
          messages << "on line #{linter.lints.first.line}"
        end
        messages.join ' '
      else
        lines = lint_lines(linter)
        ", but lints were reported on lines #{lines[0...-1].join(', ')} and #{lines.last}"
      end
  end

  failure_message_when_negated do |_linter|
    'expected that a lint would not be reported'
  end

  description do
    'report a lint' + extended_expectations(expected_line, expected_message)
  end

  def extended_expectations(expected_line, expected_message)
    (expected_line ? " on line #{expected_line}" : '') +
      (expected_message ? " with message '#{expected_message}'" : '')
  end

  def has_lints?(linter, expected_line, count, expected_message)
    if expected_line && count
      linter.lints.count == count &&
        lint_lines(linter).all? { |line| line == expected_line }
    elsif expected_line
      lint_lines(linter).include?(expected_line)
    elsif count
      linter.lints.count == count
    elsif expected_message
      lint_messages(linter).all? { |message| message == expected_message }
    else
      linter.lints.count > 0
    end
  end

  def lint_lines(linter)
    linter.lints.map(&:line)
  end

  def lint_messages(linter)
    linter.lints.map(&:message)
  end
end
