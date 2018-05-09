# == Class: dhrep::tools::check_services
#
# checks services within vm
#
class dhrep::tools::check_services (
  $scope = undef,
) inherits dhrep::params {

  $_optdir = $::dhrep::params::optdir

  # TODO Find a better solution to put service ports into check-services file!
  $crud_port    = $::dhrep::params::config['tomcat_crud']['http_port'];
  $publish_port = $::dhrep::params::config['tomcat_publish']['http_port'];
  $pid_port     = $::dhrep::params::config['tomcat_pid']['http_port'];
  $oaipmh_port  = $::dhrep::params::config['tomcat_oaipmh']['http_port'];
  $fits_port    = $::dhrep::params::config['tomcat_fits']['http_port'];
  # using crud user for checking services, not user root
  $crud_user    = $::dhrep::params::config['tomcat_crud']['user'];

  file { "${_optdir}/check-services.sh" :
    content => template("dhrep/opt/dhrep/${scope}/check-services.sh"),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$_optdir],
  }

  ###
  # cron for check-services script
  ###
  cron { 'check_services':
    command => "${_optdir}/check-services.sh &> /dev/null",
    user    => $crud_user,
    minute  => 9,
    require => File["${_optdir}/check-services.sh"],
  }

  ###
  # nrpe for tgcrud
  ###
  nrpe::plugin { 'check_check_services':
    plugin     => 'check-services.sh',
    libexecdir => $_optdir,
  }
}
