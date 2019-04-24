# == Class: dhrep::services::tomcat_tgsearch
#
# Class to install and configure tgsearch tomcat.
#
class dhrep::services::tomcat_tgsearch (
  $scope = undef,
  $xmx   = $dhrep::params::tomcat_tgsearch_xmx,
  $xms   = $dhrep::params::tomcat_tgsearch_xms,
) inherits dhrep::params {

  $catname      = $::dhrep::params::config['tomcat_tgsearch']['catname']
  $http_port    = $::dhrep::params::config['tomcat_tgsearch']['http_port']
  $control_port = $::dhrep::params::config['tomcat_tgsearch']['control_port']
  $jmx_port     = $::dhrep::params::config['tomcat_tgsearch']['jmx_port']
  $uid          = $::dhrep::params::config['tomcat_tgsearch']['uid']
  $gid          = $::dhrep::params::config['tomcat_tgsearch']['gid']

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
    keep_logs        => 2,
    tomcat_version   => $dhrep::params::tomcat_version,
  }
}
