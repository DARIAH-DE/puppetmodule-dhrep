# == Class: dhrep::services::intern::redis
#
# Class to install and configure redis.
#
class dhrep::services::intern::redis (
  $scope = undef,
) {

  # read docs at https://forge.puppet.com/arioch/redis
  class { '::redis':
    appendonly => true,
  }

  telegraf::input { 'redis':
    plugin_type => 'redis',
    options     => {
      'servers' => ["tcp://localhost:6379"],
    },
  }

}
