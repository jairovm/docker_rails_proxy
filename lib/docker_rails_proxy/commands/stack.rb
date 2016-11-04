require 'optparse'

module DockerRailsProxy
  class Stack < AwsCli
    autoload :Create,  'docker_rails_proxy/commands/stack/create'
    autoload :Destroy, 'docker_rails_proxy/commands/stack/destroy'

    RUNNING_STATUSES = %w[CREATE_COMPLETE UPDATE_COMPLETE].freeze

    attr_accessor :options

    before_initialize do
      'jq is required, `brew install jq`' unless system 'type jq &> /dev/null'
    end

    after_initialize { self.options = {} }
    after_initialize { opt_parser.parse!(arguments) }
    after_initialize { options[:profile] ||= APP_NAME }

    validates { '--profile is required.' if options[:profile].blank? }

    builds -> (params:) do
      case params[:arguments].shift
      when 'create'  then Create
      when 'destroy' then Destroy
      when 'deploy'
        klass_name = %W[
          DockerRailsProxy
          Stack
          Deploy#{params[:arguments].first.classify}
        ].join('::')

        begin
          klass_name.constantize
        rescue
          $stderr.puts "#{klass_name} class does not exit"
          exit 1
        end
      else
        puts "Usage: bin/#{APP_NAME} stack <create|destroy|deploy> [options]"
        exit
      end
    end

  private

    def stack_exist?(stack_name)
      !stack_status(stack_name).blank?
    end

    def wait_for_stack(stack_name)
      loop do
        case status = stack_status(stack_name)
        when 'CREATE_IN_PROGRESS', 'UPDATE_IN_PROGRESS', 'UPDATE_COMPLETE_CLEANUP_IN_PROGRESS'
          puts "#{stack_name} still processing: #{status}"

        when *RUNNING_STATUSES
          puts "#{stack_name} stack stabilized: #{status}"
          break

        else
          $stderr.puts %{
            There is a problem with the #{stack_name} stack: #{status}
          }
          exit 1
        end

        sleep 10
      end if stack_exist?(stack_name)
    end

    def stack_status(stack_name)
      %x(aws cloudformation describe-stacks \
        --profile '#{options[:profile]}' \
        | jq '.Stacks[] | select(.StackName == "#{stack_name}") | .StackStatus' \
        | xargs
      ).strip
    end

    def opt_parser
      @opt_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: bin/#{APP_NAME} stack #{self.class.name.demodulize.parameterize} [options]"

        opts.on(
          '--profile [PROFILE]',
          "Aws profile (Default: #{APP_NAME})"
        ) { |profile| options[:profile] = profile }

        yield opts if block_given?

        opts.on('-h', '--help', 'Display this screen') do
          puts opts
          exit
        end
      end
    end
  end
end
