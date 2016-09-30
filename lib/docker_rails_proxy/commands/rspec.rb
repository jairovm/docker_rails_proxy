module DockerRailsProxy
  class Rspec < SyncBack
    def process
      command, *args = arguments
      system "docker exec #{APP_NAME} bin/rspec #{command} #{args.join(' ')}"
    end
  end
end
