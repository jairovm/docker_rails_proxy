require 'optparse'
require 'timeout'
require 'yaml'

module DockerRailsProxy
  class Stack < AwsCli
    class Create < self
      YML_EXTENSIONS = %w(.yml .yaml).freeze

      attr_accessor :options, :data, :parameters

      before_initialize do
        'jq is required, `brew install jq`' unless system 'type jq &> /dev/null'
      end

      after_initialize { self.options, self.parameters = {}, {} }
      after_initialize :parse_options!, :set_defaults

      validates { '--profile is required.' if options[:profile].nil? }
      validates { '--ymlfile is required.' if options[:ymlfile].nil? }

      validates do
        unless File.exist? options[:ymlfile]
          "#{options[:ymlfile]} file does not exit"
        end
      end

      validates do
        unless YML_EXTENSIONS.include? File.extname(options[:ymlfile])
          "#{options[:ymlfile]} is not a yml file"
        end
      end

      before_process { self.data = YAML::load_file(options[:ymlfile]) }

      def process
        set_parameters
      end

    private

      def set_parameters
        (data['Parameters'] || {}).each do |key, attrs|
          value = nil

          while parameters[key].to_s.empty? do
            puts '=' * 100
            puts parameters.inspect
            case attrs['Type']
            when 'AWS::EC2::KeyPair::KeyName'
              key_pairs ||= %x(
                aws ec2 describe-key-pairs --profile '#{options[:profile]}' \
                  | jq '.KeyPairs[] | .KeyName' | xargs
              ).strip.split(' ')

              print_options key_pairs, "Choose a key pair number and press [ENTER] (Default: #{value})"
              parameters[key] = get_option(key_pairs, value)
            end
          end
        end
      end

      def print_options(values, message)
        puts message
        values.each_with_index { |v, i| puts "#{i}) #{v}" }
      end

      def get_option(values, default = nil)
        flush_stdin
        print ": "
        option = $stdin.gets.chomp
        option =~ /^\d+$/ ? values[option.to_i] : default
      end

      def flush_stdin
        loop do
          Timeout::timeout(0.1) { $stdin.gets.chomp } rescue break
        end
      end

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

          opts.on('--ymlfile YMLFILE', 'Stack YML file') do |ymlfile|
            options[:ymlfile] = build_path(ymlfile)
          end

          opts.on('-h', '--help', 'Display this screen') do
            puts opts
            exit
          end
        end
      end
    end
  end
end
