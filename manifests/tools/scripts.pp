# == Class: dhrep::tools::scripts
#
# install ans configure scripts, such as check-services and init-databases within the vm
#
class dhrep::tools::scripts (
  $scope = undef,
) inherits dhrep::params {

  $_optdir = $::dhrep::params::optdir

  # TODO Find a better solution to put service ports into check-services file!
  $crud_port    = $::dhrep::params::config['tomcat_crud']['http_port'];
  $publish_port = $::dhrep::params::config['tomcat_publish']['http_port'];
  $pid_port     = $::dhrep::params::config['tomcat_pid']['http_port'];
  $oaipmh_port  = $::dhrep::params::config['tomcat_oaipmh']['http_port'];
  $fits_port    = $::dhrep::params::config['tomcat_fits']['http_port'];

  file { "${_optdir}/check-services.sh" :
    content => template("dhrep/opt/dhrep/${scope}/check-services.sh.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$_optdir],
  }

  # TODO create init-databases script for scope dariah, too!
  if $scope == 'textgrid' {
    file { "${_optdir}/init-databases.sh" :
      content => template("dhrep/opt/dhrep/${scope}/init-databases.sh.erb"),
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File[$_optdir],
    }
  }

  ###
  # nrpe for check_services.sh
  ###
  nrpe::plugin { 'check_services':
    plugin     => 'check-services.sh -s',
    libexecdir => $_optdir,
  }
}
