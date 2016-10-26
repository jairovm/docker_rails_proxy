require 'optparse'

module DockerRailsProxy
  class Stack < AwsCli
    class Destroy < self
      attr_accessor :options

      after_initialize { self.options = {} }
      after_initialize :parse_options!, :set_defaults

      validates { '--profile is required.' if options[:profile].nil? }

      def process
        puts options.inspect
      end

    private

      def set_defaults
        options[:profile] ||= APP_NAME
      end

      def parse_options!
        opt_parser.parse!(arguments)
      end

      def opt_parser
        @opt_parser ||= OptionParser.new do |opts|
          opts.banner = "Usage: bin/#{APP_NAME} create-stack [options]"

          opts.on(
            '--profile [PROFILE]',
            "Aws profile (Default: #{APP_NAME})"
          ) { |profile| options[:profile] = profile }

          opts.on('-h', '--help', 'Display this screen') do
            puts opts
            exit
          end
        end
      end
    end
  end
end
