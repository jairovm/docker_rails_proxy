module DockerRailsProxy
  class Spring < DockerMainApp
    def process
      command, *args = arguments
      system "docker exec #{APP_NAME} bin/spring #{command} #{args.join(' ')}"
    end
  end
end
