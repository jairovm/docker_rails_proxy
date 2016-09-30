module DockerRailsProxy
  class Cli
    class << self
      def invoke(arguments)
        command, *args = arguments

        if command.nil?
          $stderr.puts <<-EOF
          #{"bin/#{APP_NAME} requires 1 argument.".bold}

          #{"Usage: bin/#{APP_NAME} <command> [<args>]".bold}
          EOF
          exit 1
        end

        if COMMANDS.include? command
          args << '-h' if args.empty?
          "DockerRailsProxy::#{command}".constantize.(arguments: args)
        else
          $stderr.puts <<-EOS
          #{'No such command'.yellow}

          #{'COMMANDS'.bold}
          EOS

          COMMANDS.each do |script|
            $stderr.puts <<-EOS
            #{script.parameterize.bold} [<args>]
            EOS
          end

          exit 1
        end
      end
    end
  end
end
