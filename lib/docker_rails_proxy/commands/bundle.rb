module DockerRailsProxy
  class Bundle < SyncBack
    def process
      command, *args = arguments
      system "docker exec -it #{APP_NAME} bundle #{command} #{args.join(' ')}"
    end
  end
end
