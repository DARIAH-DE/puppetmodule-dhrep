# == Class: dhrep::tools::check_services
#
# checks services within vm
#
class dhrep::tools::check_services (
  $scope = undef,
) inherits dhrep::params {

  $_optdir = $::dhrep::params::optdir

  file { "${_optdir}/check-services.sh" :
    source  => "puppet:///modules/dhrep/opt/dhrep/${scope}/check-services.sh",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$_optdir],
  }
}
