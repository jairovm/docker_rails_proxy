module DockerRailsProxy
  class Compose < Docker
    class Override < self
      OVERRIDE_PATH = build_path('docker-compose.override.yml')
      OVERRIDE_FILE = <<EOS.freeze
version: "2"
services:
  app:
    volumes:
      - #{build_path(".data-bags/certs/localhost.#{APP_NAME}/cert.crt:/certs/cert.crt")}
      - #{build_path(".data-bags/certs/localhost.#{APP_NAME}/cert.key:/certs/cert.key")}
EOS

      def process
        File.write(OVERRIDE_PATH, OVERRIDE_FILE)
        puts "#{OVERRIDE_PATH} was created"
      end
    end
  end
end
