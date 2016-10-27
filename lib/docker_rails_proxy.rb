Dir[File.expand_path('../docker_rails_proxy/extends/*.rb', __FILE__)].map do |f|
  require f
end

module DockerRailsProxy
  COMMANDS = Dir[File.expand_path('../docker_rails_proxy/commands/*.rb', __FILE__)].map do |f|
    File.basename(f, '.rb').parameterize
  end.freeze

  COMMANDS.each do |c|
    autoload c.classify.to_sym, "docker_rails_proxy/commands/#{c.underscore}"
  end

  autoload :InheritableAttributes, 'docker_rails_proxy/concerns/inheritable_attributes'
  autoload :Callbacks,             'docker_rails_proxy/concerns/callbacks'
  autoload :Rsync,                 'docker_rails_proxy/concerns/rsync'

  autoload :Cli,     'docker_rails_proxy/cli'
  autoload :VERSION, 'docker_rails_proxy/version'

  class Base
    include InheritableAttributes
    include Callbacks
    include Rsync

    attr_reader :arguments

    def initialize(arguments:)
      @arguments = arguments
    end

    class << self
      def build_path(path = nil)
        File.join(APP_PATH, block_given? ? yield : path)
      end

      def call(options)
        klass = _run_build_callbacks params: options

        klass.send :_run_before_initialize_callbacks

        resource = klass.new(options)

        klass.send :_run_after_initialize_callbacks, resource: resource

        klass.send :_run_validation_callbacks, resource: resource

        klass.send :_run_before_process_callbacks, resource: resource

        result = resource.process

        klass.send :_run_after_process_callbacks, resource: resource
        result
      end
    end

    def process
      raise NotImplementedError, 'Subclasses must implement a process method'
    end

  private

    def build_path(*args, &block)
      self.class.build_path(*args, &block)
    end

    def print_options(values, message)
      puts message
      values.each_with_index { |v, i| puts "#{i}) #{v}" }
    end

    def get_option(values, default = nil)
      flush_stdin
      print ": "
      option = $stdin.gets.chomp

      return default if option.blank?
      option =~ /^\d+$/ ? values[option.to_i] : nil
    end

    def flush_stdin
      loop do
        Timeout::timeout(0.1) { $stdin.gets.chomp } rescue break
      end
    end
  end

  class AwsCli < Base
    before_initialize do
      unless system 'type aws &> /dev/null'
        'aws is required, `brew install awscli`'
      end
    end
  end

  class Docker < Base
    before_initialize do
      if ENV['DOCKER_HOST'].nil?
        %(
        Couldn't connect to Docker daemon you might need to run:
          docker-machine start default
          eval $(docker-machine env default)
        )
      end
    end
  end

  class DockerMainApp < Docker
    before_initialize do
      unless system "docker ps | grep '#{APP_NAME}$' &> /dev/null"
        %(
        Couldn't connect to #{APP_NAME} container you might need to run:
          bin/#{APP_NAME} compose up
        )
      end
    end

    # Makes sure the container is in sync with the APP_PATH
    before_process { sync source: APP_PATH, silent: true }
  end

  class SyncBack < DockerMainApp
    after_process { system "docker exec #{APP_NAME} chown -R nobody:nogroup ." }
    after_process { sync source: APP_PATH, reverse: true }
  end
end
