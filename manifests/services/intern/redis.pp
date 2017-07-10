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
}
