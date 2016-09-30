require 'optparse'

module DockerRailsProxy
  class Build < Docker
    attr_accessor :options

    after_initialize { self.options = {} }
    after_initialize :parse_options!

    validates do
      if options[:dockerfile].nil?
        '--dockerfile is required'
      elsif !File.exist?(options[:dockerfile])
        "#{options[:dockerfile]} dockerfile does not exist."
      end
    end

    validates { '--tag is required' if options[:tag].nil? }

    validates do
      options[:build_args] ||= {}

      args = File.readlines(options[:dockerfile]).map do |line|
        /^ARG/ =~ line ? line.split(' ').last : nil
      end.compact

      missings = args.select { |arg| options[:build_args][arg].nil? }.compact

      (options[:build_args].keys - args).each { |k| options[:build_args].delete k }

      missings.map { |a| "#{a} is required" }.join(', ') unless missings.empty?
    end

    def process
      system <<-EOS
        docker build \
          -f '#{options[:dockerfile]}' \
          -t '#{options[:tag]}' \
          #{build_args} \
          '#{APP_PATH}'
      EOS
    end

  private

    def build_args
      options[:build_args].map do |k, v|
        "--build-arg #{k.upcase}='#{v.strip}'"
      end.join(' ')
    end

    def parse_options!
      opt_parser.parse!(arguments)
    end

    def opt_parser
      @opt_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: bin/#{APP_NAME} build [options]"

        opts.on('--dockerfile DOCKERFILE', 'Dockerfile') do |dockerfile|
          options[:dockerfile] = dockerfile
        end

        opts.on('--tag TAG', 'Docker Image Tag') { |tag| options[:tag] = tag }

        opts.on('--build-args A=val,B=val...', Array, 'Docker build-args') do |o|
          options[:build_args] = Hash[o.map { |s| s.split('=', 2) }]
        end

        opts.on('-h', '--help', 'Display this screen') do
          puts opts
          exit
        end
      end
    end
  end
end
