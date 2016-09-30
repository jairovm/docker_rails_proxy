require 'optparse'

module DockerRailsProxy
  class DataBags < AwsCli
    attr_accessor :options

    after_initialize { self.options = {} }
    after_initialize :parse_options!, :set_defaults

    before_process :set_folder_and_bucket

    validates { '--profile is required.' if options[:profile].nil? }
    validates { '--bucket is required.'  if options[:bucket].nil?  }

    def process
      case arguments.first
      when 'pull' then pull
      when 'push' then push
      else
        opt_parser.parse %w(-h)
      end
    end

  private

    def pull
      if system <<-EOS.strip
        aws s3 sync '#{options[:bucket]}' '#{options[:folder]}' \
          --delete \
          --exact-timestamps \
          --profile '#{options[:profile]}'
      EOS

        puts "Data bags pulled from #{options[:bucket]} to #{options[:folder]}"
      end
    end

    def push
      puts "#{options[:bucket]} will be synced with #{options[:folder]}, are you sure?: [yes]"
      confirm = $stdin.gets.chomp

      exit unless confirm == 'yes'

      if system <<-EOS
        aws s3 sync '#{options[:folder]}' '#{options[:bucket]}' \
          --delete \
          --exact-timestamps \
          --profile '#{options[:profile]}' \
          --sse aws:kms
      EOS

        puts "Data bags pushed from #{options[:folder]} to #{options[:bucket]}"
      end
    end

    def set_defaults
      options[:profile] ||= APP_NAME
      options[:bucket]  ||= "#{APP_NAME}-data-bags"
    end

    def set_folder_and_bucket
      options[:folder] = build_path('.data-bags')
      options[:bucket] = "s3://#{options[:bucket]}"
    end

    def parse_options!
      opt_parser.parse!(arguments)
    end

    def opt_parser
      @opt_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: bin/#{APP_NAME} data-bags <pull|push> [options]"

        opts.on(
          '--profile [PROFILE]',
          "Aws profile (Default: #{APP_NAME})"
        ) { |profile| options[:profile] = profile }

        opts.on(
          '--bucket [BUCKET]',
          "AWS S3 Data bags bucket (Default: #{APP_NAME}-data-bags)"
        ) { |bucket| options[:bucket] = bucket }

        opts.on('-h', '--help', 'Display this screen') do
          puts opts
          exit
        end
      end
    end
  end
end
