require 'optparse'

module DockerRailsProxy
  class DataBags < AwsCli
    autoload :Pull, 'docker_rails_proxy/commands/data_bags/pull'
    autoload :Push, 'docker_rails_proxy/commands/data_bags/push'

    EXCLUDE = %w[.summary *.swp *.DS_Store].freeze

    attr_accessor :options, :local_summary

    after_initialize { self.options = {} }
    after_initialize :parse_options!, :set_defaults

    validates { '--profile is required.' if options[:profile].nil? }
    validates { '--bucket is required.'  if options[:bucket].nil?  }

    validates do
      unless system <<-EOS.strip
        aws s3 ls --profile '#{options[:profile]}' | grep '#{options[:bucket]}'
      EOS

        "#{options[:bucket]} bucket does not exit."
      end
    end

    after_process do
      if File.directory?(options[:folder])
        File.write(options[:summary_path], bucket_summary.strip)
      end
    end

    builds -> (params:) do
      case params[:arguments].shift
      when 'pull' then Pull
      when 'push' then Push
      else
        puts "Usage: bin/#{APP_NAME} #{command} <pull|push> [options]"
        exit
      end
    end

  private

    def bucket_summary
      summary = %x(
        aws s3 ls '#{options[:bucket]}' --summarize --recursive \
          --profile '#{options[:profile]}' | grep -v '^$' | sort -n
      ).strip.split("\n")

      # 0 => Total Size
      # 1 => Total Objects
      # last => last updated file
      (summary[ 0..1 ] << summary.last).map{|s| s.gsub(/\D/, ''.freeze) }.join('-')
    end

    def exclude_args
      EXCLUDE.map{|s| "--exclude '#{s}'" }.join(' ')
    end

    def set_defaults
      options[:profile] ||= APP_NAME
      options[:bucket]  ||= "#{APP_NAME}-data-bags"

      options[:bucket_path]  = "s3://#{options[:bucket]}"
      options[:folder]       = build_path(".data-bags/#{options[:bucket]}")
      options[:summary_path] = "#{options[:folder]}/.summary"
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
