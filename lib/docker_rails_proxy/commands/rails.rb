module DockerRailsProxy
  class Rails < SyncBack
    def process
      command, *args = arguments

      case command
      when 'c',  'console'    then console args
      when 'db', 'dbconsole'  then db args
      when 'logs'             then logs args
      when 'restart', 'touch' then restart
      else
        system "docker exec -it #{APP_NAME} bin/rails #{command} #{args.join(' ')}"
      end
    end

  private

    def console(args)
      exec "docker exec -it #{APP_NAME} bin/rails c #{args.join(' ')}"
    end

    def db(args)
      exec <<-EOS
        docker exec -it #{APP_NAME}_db \
          mysql #{args.first || "#{APP_NAME}_development"}
      EOS
    end

    def logs(args)
      exec <<-EOS
        docker exec #{APP_NAME} tail -f log/#{args.first || 'development'}.log
      EOS
    end

    def restart
      exec "docker exec #{APP_NAME} touch tmp/restart.txt"
    end
  end
end
