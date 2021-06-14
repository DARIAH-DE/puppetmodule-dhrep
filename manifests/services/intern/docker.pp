class dhrep::services::intern::docker (
  $docker_image_registry = 'docker.gitlab.gwdg.de',
) inherits dhrep::params {

  class { '::docker' :
    version => 'latest',
  }
  class {'docker::compose':
    version => '1.25.4',
  }
  docker::registry { $docker_image_registry: }

}
