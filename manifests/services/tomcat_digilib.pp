# == Class: dhrep::services::tomcat_digilib
#
# Class to install and configure digilib tomcat.
#
class dhrep::services::tomcat_digilib (
  $scope = undef,
) inherits dhrep::params {

  $catname      = $::dhrep::params::config['tomcat_digilib']['catname']
  $http_port    = $::dhrep::params::config['tomcat_digilib']['http_port']
  $control_port = $::dhrep::params::config['tomcat_digilib']['control_port']
  $jmx_port     = $::dhrep::params::config['tomcat_digilib']['jmx_port']
  $gid          = $::dhrep::params::config['tomcat_digilib']['gid']
  $uid          = $::dhrep::params::config['tomcat_digilib']['uid']
  $user         = $catname
  $group        = $catname
  $template     = 'dhrep/etc/default/tomcat.erb'

  ###
  # user, home-dir and user-tomcat
  ###
  dhrep::resources::servicetomcat { $catname:
    user              => $user,
    group             => $group,
    gid               => $gid,
    uid               => $uid,
    http_port         => $http_port,
    control_port      => $control_port,
    jmx_port          => $jmx_port,
    defaults_template => $template,
  }
}
