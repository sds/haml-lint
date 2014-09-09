module HamlLint
  # Encapsulates all communication to an output source.
  class Logger
    # Creates a logger which outputs nothing.
    # @return [HamlLint::Logger]
    def self.silent
      new(File.open('/dev/null', 'w'))
    end

    # Creates a new {HamlLint::Logger} instance.
    #
    # @param out [IO] the output destination.
    def initialize(out)
      @out = out
    end

    # Print the specified output.
    #
    # @param output [String] the output to send
    # @param newline [true,false] whether to append a newline
    # @return [nil]
    def log(output, newline = true)
      @out.print(output)
      @out.print("\n") if newline
    end

    # Print the specified output in bold face.
    # If output destination is not a TTY, behaves the same as {#log}.
    #
    # @param output [String] the output to send
    # @param newline [true,false] whether to append a newline
    # @return [nil]
    def bold(*args)
      color('1;37', *args)
    end

    # Print the specified output in a color indicative of error.
    # If output destination is not a TTY, behaves the same as {#log}.
    #
    # @param output [String] the output to send
    # @param newline [true,false] whether to append a newline
    # @return [nil]
    def error(*args)
      color(31, *args)
    end

    # Print the specified output in a bold face and color indicative of error.
    # If output destination is not a TTY, behaves the same as {#log}.
    #
    # @param output [String] the output to send
    # @param newline [true,false] whether to append a newline
    # @return [nil]
    def bold_error(*args)
      color('1;31', *args)
    end

    # Print the specified output in a color indicative of success.
    # If output destination is not a TTY, behaves the same as {#log}.
    #
    # @param output [String] the output to send
    # @param newline [true,false] whether to append a newline
    # @return [nil]
    def success(*args)
      color(32, *args)
    end

    # Print the specified output in a color indicative of a warning.
    # If output destination is not a TTY, behaves the same as {#log}.
    #
    # @param output [String] the output to send
    # @param newline [true,false] whether to append a newline
    # @return [nil]
    def warning(*args)
      color(33, *args)
    end

    # Print specified output in bold face in a color indicative of a warning.
    # If output destination is not a TTY, behaves the same as {#log}.
    #
    # @param output [String] the output to send
    # @param newline [true,false] whether to append a newline
    # @return [nil]
    def bold_warning(*args)
      color('1;33', *args)
    end

    # Print the specified output in a color indicating information.
    # If output destination is not a TTY, behaves the same as {#log}.
    #
    # @param output [String] the output to send
    # @param newline [true,false] whether to append a newline
    # @return [nil]
    def info(*args)
      color(36, *args)
    end

    private

    def color(code, output, newline = true)
      log(@out.tty? ? "\033[#{code}m#{output}\033[0m" : output, newline)
    end
  end
end
