# == Class: dhrep::services::tomcat_sesame
#
# Class to install and configure sesame.
#
class dhrep::services::tomcat_sesame (
  $scope = undef,
  $xmx   = $::dhrep::params::tomcat_sesame_xmx,
  $xms   = $::dhrep::params::tomcat_sesame_xms,
) inherits dhrep::params {

  $catname      = $::dhrep::params::config['tomcat_sesame']['catname']
  $http_port    = $::dhrep::params::config['tomcat_sesame']['http_port']
  $control_port = $::dhrep::params::config['tomcat_sesame']['control_port']
  $jmx_port     = $::dhrep::params::config['tomcat_sesame']['jmx_port']
  $uid          = $::dhrep::params::config['tomcat_sesame']['uid']
  $gid          = $::dhrep::params::config['tomcat_sesame']['gid']

  ###
  # user, home-dir and user-tomcat
  ###
  usertomcat::instance { $catname:
    uid              => $uid,
    gid              => $gid,
    http_port        => $http_port,
    control_port     => $control_port,
    jmx_port         => $jmx_port,
    xmx              => $xmx,
    xms              => $xms,
    telegraf_enabled => true,
    tomcat_version   => $dhrep::params::tomcat_version,
  }
}
