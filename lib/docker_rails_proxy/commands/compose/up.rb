require 'pty'
require 'optparse'

module DockerRailsProxy
  class Compose < Docker
    class Up < self
      FSWATCH_CMD = <<-EOS.strip.freeze
        fswatch -r -0 \
          --latency=0.1 \
          --exclude '.git' \
          --exclude '4913' \
          "#{APP_PATH}" "#{GEMS_PATH}" | xargs -0 -n1 -I{} echo {}
      EOS

      EIO_ERROR = %(
        Errno:EIO error, but this probably just means that the process
        has finished giving output
      ).freeze

      attr_accessor :branch_name, :stopping, :options, :from_scratch

      alias_method :stopping?, :stopping
      alias_method :from_scratch?, :from_scratch

      before_initialize do
        unless system 'type fswatch &> /dev/null'
          'fswatch is required, `brew install fswatch`'
        end
      end

      after_initialize { self.options = {} }
      after_initialize { self.branch_name = current_branch }

      after_initialize :parse_options!, :set_defaults

      before_process do
        self.from_scratch = %x(docker-compose ps | grep -c #{APP_NAME}).to_i.zero?
      end

      after_process { fswatch_start }

      def process
        system 'docker-compose up -d'
        sync_app_and_gems_folders
        run_bundle_install if options[:bundle]
        seed if from_scratch?
      end

    private

      def seed
        system <<-EOS.strip.freeze
          docker exec #{APP_NAME} bin/rake db:drop db:create db:migrate db:seed
        EOS
      end

      def sync_app_and_gems_folders
        rsync_app
        sync source: GEMS_PATH
      end

      def rsync_app
        loop do
          break if sync(source: APP_PATH)
          puts "waiting for rsync-volume service on #{rsync_host}"
          sleep 2
        end
      end

      def fswatch_start
        PTY.spawn(FSWATCH_CMD) do |stdout, stdin, pid|
          begin
            stdout.each { |path| sync_or_kill(path: path, pid: pid) }
          rescue Errno::EIO
            $stderr.puts EIO_ERROR
          end
        end
      rescue PTY::ChildExited
        $stderr.puts '"The fswatch process exited!'
      end

      def sync_or_kill(path:, pid:)
        return if stopping?

        if branch_name == (branch = current_branch)
          sync source: path
        else
          $stderr.puts %(
          `git checkout #{branch}` was detected, stopping fswatch
          Previous branch was '#{branch_name}'
          )
          Process.kill(9, pid)
          self.stopping = true
        end
      end

      def current_branch
        %x(git rev-parse --abbrev-ref HEAD).strip
      end

      # since new gems may have been added, we need bundle install
      def run_bundle_install
        system "docker exec #{APP_NAME} bundle install"
      end

      def parse_options!
        opt_parser.parse!(arguments)
      end

      def set_defaults
        options[:bundle] = true if options[:bundle].nil?
      end

      def opt_parser
        @opt_parser ||= OptionParser.new do |opts|
          opts.banner = "Usage: bin/#{APP_NAME} compose up [options]"

          opts.on(
            '--[no-]bundle',
            'Run bundle install in all related containers'
          ) { |bundle| options[:bundle] = bundle }

          opts.on('-h', '--help', 'Display this screen') do
            puts opts
            exit
          end
        end
      end
    end
  end
end
