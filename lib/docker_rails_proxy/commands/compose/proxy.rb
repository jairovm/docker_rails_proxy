module DockerRailsProxy
  class Compose < Docker
    class Proxy < self
      def process
        command, *args = arguments
        system "docker-compose #{command} #{args.join(' ')}"
      end
    end
  end
end
