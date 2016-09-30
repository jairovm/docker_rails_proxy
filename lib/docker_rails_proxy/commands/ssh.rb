require 'optparse'

module DockerRailsProxy
  class Ssh < DockerMainApp
    def process
      command, *args = arguments

      case command
      when '-h', '--help'
        opt_parser.parse %w(-h)
      else
        system "docker exec -it #{APP_NAME} #{command} #{args.join(' ')}"
      end
    end

  private

    def opt_parser
      @opt_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: bin/#{APP_NAME} ssh COMMAND [options]"

        opts.on('-h', '--help', 'Display this screen') do
          puts opts
          exit
        end
      end
    end
  end
end
