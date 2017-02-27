# == Class: dhrep::services::tomcat_digilib
#
# Class to install and configure digilib tomcat.
#
class dhrep::services::tomcat_digilib (
  $scope = undef,
  $xmx   = $::dhrep::params::tomcat_digilib_xmx,
  $xms   = $::dhrep::params::tomcat_digilib_xms,
) inherits dhrep::params {

  $catname      = $::dhrep::params::config['tomcat_digilib']['catname']
  $http_port    = $::dhrep::params::config['tomcat_digilib']['http_port']
  $control_port = $::dhrep::params::config['tomcat_digilib']['control_port']
  $jmx_port     = $::dhrep::params::config['tomcat_digilib']['jmx_port']
  $uid          = $::dhrep::params::config['tomcat_digilib']['uid']
  $gid          = $::dhrep::params::config['tomcat_digilib']['gid']

  ###
  # user, home-dir and user-tomcat
  ###
  usertomcat::create { $catname:
    uid               => $uid,
    gid               => $gid,
    http_port         => $http_port,
    control_port      => $control_port,
    jmx_port          => $jmx_port,
    xmx               => $xmx,
    xms               => $xms,
    collectd_enabled  => true,
  }
}
