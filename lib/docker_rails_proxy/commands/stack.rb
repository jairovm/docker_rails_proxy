module DockerRailsProxy
  class Stack < AwsCli
    autoload :Create,  'docker_rails_proxy/commands/stack/create'
    autoload :Destroy, 'docker_rails_proxy/commands/stack/destroy'

    builds -> (params:) do
      case params[:arguments].first
      when 'create'  then Create
      when 'destroy' then Destroy
      else
        puts "Usage: bin/#{APP_NAME} stack <create|destroy> [options]"
        exit
      end
    end
  end
end
