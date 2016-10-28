require 'optparse'

module DockerRailsProxy
  class Stack < AwsCli
    class Destroy < self
      attr_accessor :options, :stacks

      after_initialize { self.options = {} }
      after_initialize :parse_options!, :set_defaults

      validates { '--profile is required.' if options[:profile].nil? }

      before_process do
        jq_command = <<-EOS
          .Stacks
          | map(
            select(
              .StackStatus | inside("CREATE_COMPLETE UPDATE_COMPLETE")
            )
          | .StackName
          )
          | sort[]
        EOS

        self.stacks = %x(
          aws cloudformation describe-stacks --profile '#{options[:profile]}' \
          | jq '#{jq_command}' | xargs
        ).strip.split(' ')

        if stacks.empty?
          $stderr.puts 'There are no stacks running'
          exit 1
        end
      end

      def process
        begin
          print_options(stacks, 'Choose the stack number and press [ENTER]')
          stack_name = get_option(stacks)
        end while stack_name.blank?

        puts "You're about to destroy this stack: #{stack_name}, are you sure? [yes]:"
        exit unless $stdin.gets.chomp == 'yes'

        puts "Destroying #{stack_name} stack"

        system <<-EOS
          aws cloudformation delete-stack \
            --stack-name '#{stack_name}' \
            --profile '#{options[:profile]}'
        EOS
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
