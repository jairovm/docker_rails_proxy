module DockerRailsProxy
  class Rake < SyncBack
    def process
      command, *args = arguments
      system "docker exec -it #{APP_NAME} bin/rake #{command} #{args.join(' ')}"
    end
  end
end
