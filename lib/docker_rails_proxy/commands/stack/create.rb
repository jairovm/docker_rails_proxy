require 'json'
require 'timeout'
require 'yaml'

module DockerRailsProxy
  class Stack < AwsCli
    class Create < self
      YML_EXTENSIONS = %w(.yml .yaml).freeze

      attr_accessor :data, :parameters, :outputs

      after_initialize { self.parameters, self.outputs = {}, {} }
      after_initialize :set_defaults

      validates { '--stack-name is required.' if options[:stack_name].blank? }
      validates { '--ymlfile is required.'    if options[:ymlfile].blank?    }

      validates do
        unless File.exist? options[:ymlfile]
          "#{options[:ymlfile]} file does not exit"
        end
      end

      validates do
        if YML_EXTENSIONS.include? File.extname(options[:ymlfile])
          self.data          = YAML::load_file(options[:ymlfile])
          options[:jsonfile] = options[:ymlfile].sub(/\..+/, '.json')
          File.write(options[:jsonfile], data.to_json)
        else
          "#{options[:ymlfile]} is not a yml file"
        end
      end

      validates do
        unless system <<-EOS
          aws cloudformation validate-template \
            --template-body 'file://#{options[:jsonfile]}' \
            --profile '#{options[:profile]}' \
            > /dev/null
        EOS

          %{
            Invalid template. See above errors
          }
        end
      end

      before_process { set_outputs unless options[:import_outputs_from].empty? }
      before_process { set_parameters }

      after_process { File.delete(options[:jsonfile]) if File.exist?(options[:jsonfile]) }

      def process
        system <<-EOS
          aws cloudformation create-stack \
            --stack-name '#{options[:stack_name]}' \
            --parameters #{parameters.join(' ')} \
            --template-body 'file://#{options[:jsonfile]}' \
            --capabilities 'CAPABILITY_IAM' \
            --profile '#{options[:profile]}'
        EOS
      end

    private

      def set_outputs
        jq_command = <<-EOS
            .Stacks[]
            | select(
              .StackName as $name
              | "#{options[:import_outputs_from].join(' ')}"
              | split(" ")
              | map(. == $name)
              | index(true) >= 0
            )
            | .Outputs[]
            | [ .OutputKey, .OutputValue ]
            | join("=")
        EOS

        outputs_data = %x(
          aws cloudformation describe-stacks --profile '#{options[:profile]}' \
            | jq '#{jq_command}' | xargs
        ).strip.split(' ')

        outputs_data.each do |string|
          key, value = string.split('=')
          self.outputs[key] = value
        end
      end

      def set_parameters
        (data['Parameters'] || {}).each do |key, attrs|
          parameters[key] = options[:parameters][key]
          parameters[key] ||= outputs[key]

          next if parameters[key].present?

          puts '-' * 100

          while parameters[key].to_s.blank? do
            value = nil

            case attrs['Type']
            when 'AWS::EC2::KeyPair::KeyName'
              key_pairs ||= %x(
                aws ec2 describe-key-pairs --profile '#{options[:profile]}' \
                  | jq '.KeyPairs[] | .KeyName' | xargs
              ).strip.split(' ')

              print_options(key_pairs, "Choose an option for #{key} and press [ENTER]")
              parameters[key] = get_option(key_pairs, value)

            else
              value ||= attrs['Default']

              allowed_values = Array(attrs['AllowedValues'])

              if allowed_values.empty?
                print "Enter #{key} value and press [ENTER] (Default: #{value}): "
                flush_stdin

                parameters[key] = $stdin.gets.chomp || value
                parameters[key] = value if parameters[key].blank?
              else
                print_options(allowed_values, "Choose an option for #{key} and press [ENTER] (Default: #{value})")
                parameters[key] = get_option(allowed_values, value)
              end
            end
          end
        end

        self.parameters = parameters.map do |key, value|
          "ParameterKey=\"#{key}\",ParameterValue=\"#{value}\",UsePreviousValue=false"
        end
      end

      def set_defaults
        options[:parameters]          ||= {}
        options[:import_outputs_from] ||= []
      end

      def opt_parser
        super do |opts|
          opts.on('--stack-name STACK_NAME', 'Stack Name') do |stack_name|
            options[:stack_name] = stack_name
          end

          opts.on('--ymlfile YMLFILE', 'Stack YML file') do |ymlfile|
            options[:ymlfile] = build_path(ymlfile)
          end

          opts.on('--parameters A=val,B=val...', Array, 'CF parameters') do |o|
            options[:parameters] = Hash[o.map { |s| s.split('=', 2) }]
          end

          opts.on('--import-outputs-from a,b...', Array, 'CF stack names') do |list|
            options[:import_outputs_from] = list
          end
        end
      end
    end
  end
end
