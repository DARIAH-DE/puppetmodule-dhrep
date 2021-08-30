# == Class: dhrep::services::tgmarketplace
#
# Class to install and configure the TextGrid Marketplace.
#
class dhrep::services::tgmarketplace (
  $scope                 = undef,
  $docker_image_registry = 'docker.gitlab.gwdg.de',
  $docker_image_name     = 'dariah-de/textgridlab-marketplace/develop',
  $docker_image_tag      = 'latest',
) inherits dhrep::params {

  #
  # tgmarketplace docker
  #
  include dhrep::services::intern::docker

  file { '/opt/docker-marketplace':
    ensure  => directory,
  }

  file { '/opt/docker-marketplace/marketplace.env':
    ensure  => file,
    content => epp('dhrep/opt/docker-marketplace/marketplace.env.epp', {
      hostname => $profiles::textgridrepository::public_hostname,
    }),
  }

  file { '/opt/docker-marketplace/docker-compose.yaml':
    ensure  => file,
    content => epp('dhrep/opt/docker-marketplace/docker-compose.yaml.epp', {
      image => "${docker_image_registry}/${docker_image_name}:${docker_image_tag}",
    }),
  }

  docker::image { "${docker_image_registry}/${docker_image_name}":
    ensure    => latest,
    image_tag => $docker_image_tag,
  }
  -> docker_compose { 'marketplace':
    ensure        => present,
    compose_files => ['/opt/docker-marketplace/docker-compose.yaml'],
    require       => [
                        File['/opt/docker-marketplace/docker-compose.yaml'],
                        File['/opt/docker-marketplace/marketplace.env'],
                      ],
  }

}

