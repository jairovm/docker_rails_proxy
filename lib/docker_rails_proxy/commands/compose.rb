module DockerRailsProxy
  class Compose < Docker
    autoload :Down,     'docker_rails_proxy/commands/compose/down'
    autoload :Override, 'docker_rails_proxy/commands/compose/override'
    autoload :Proxy,    'docker_rails_proxy/commands/compose/proxy'
    autoload :Up,       'docker_rails_proxy/commands/compose/up'

    builds -> (params:) do
      case params[:arguments].first
      when 'down'     then Down
      when 'override' then Override
      when 'up'       then Up
      else
        Proxy
      end
    end
  end
end
