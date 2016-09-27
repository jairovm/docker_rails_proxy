Gem::Specification.new do |s|
  s.name          = 'docker_rails_proxy'
  s.version       = '0.0.0'
  s.summary       = 'docker, docker-compose and rails wrapper'
  s.description   = 'Configures docker-compose and provides rails command helpers'

  s.license       = 'MIT'

  s.authors       = %w(Jairo Vázquez)
  s.email         = %w(jairovm20@gmail.com)
  s.homepage      = 'https://github.com/jairovm/docker_rails_proxy'

  s.files         = Dir["CHANGELOG.md", "MIT-LICENSE", "README.md", "lib/**/*"]
  s.require_paths = 'lib'
end
