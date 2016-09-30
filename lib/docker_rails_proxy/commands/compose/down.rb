module DockerRailsProxy
  class Compose < Docker
    class Down < self
      def process
        containers = %x(
          docker-compose ps | grep '#{APP_NAME}' | awk '{print $1}' | xargs
        ).strip.split(' ')

        system "docker stop #{containers.join(' ')}"
        system "docker rm -v #{containers.join(' ')}"
        system 'docker-compose down'
      end
    end
  end
end
