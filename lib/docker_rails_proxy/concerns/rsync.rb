module DockerRailsProxy
  module Rsync
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
    end

    def sync(source:, reverse: false, silent: false)
      _rsync.sync source: source, reverse: reverse, silent: silent
    end

  private

    def _rsync_host
      @_rsync_host ||= begin
        "rsync://#{ENV['DOCKER_HOST'].to_s.sub('tcp://', '').sub(/:\d+$/, '')}:10873"
      end
    end

    def _rsync
      @_rsync ||= Sync.new(rsync_host: _rsync_host)
    end

    class Sync
      attr_reader :rsync_host

      def initialize(rsync_host:)
        @rsync_host = rsync_host
      end

      def self.call(rsync_host:, **options)
        new(rsync_host: rsync_host).sync(options)
      end

      def sync(options)
        source, target, volume = normalize_options(options)

        result = send "sync_#{volume}", source: source, target: target

        if result && options[:silent].eql?(false)
          puts "#{source}   =======>   #{target}"
        end

        result
      end

    private

      def normalize_options(source:, reverse: false, **)
        values = if source.include? APP_PATH
                   ["#{APP_PATH}/", 'app']
                 elsif source.include? GEMS_PATH
                   ["#{GEMS_PATH}/", 'gems']
                 else
                   $stderr.puts "There is no rsync volume related with this path: #{source}"
                   exit 1
                 end

        paths = [values.first, "#{rsync_host}/#{values.last}"]

        [paths.send(reverse ? :reverse : :to_a), values.last].flatten
      end

      def sync_app(source:, target:)
        system <<-EOS
        rsync -avqP --no-owner --no-group \
          --exclude 'tmp/cache' \
          --exclude 'tmp/letter_opener' \
          --exclude 'tmp/pids' \
          --exclude 'log' \
          --exclude '.git*' \
          --force \
          --delete \
          #{source} #{target}
        EOS
      end

      def sync_gems(source:, target:)
        system <<-EOS
        rsync -avqP --no-owner --no-group \
          --exclude '.git*' \
          --force \
          --delete \
          #{source} #{target}
        EOS
      end
    end
  end
end
