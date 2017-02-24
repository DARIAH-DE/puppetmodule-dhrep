# == Class: dhrep::services::tomcat_tgsearch
#
# Class to install and configure tgsearch tomcat.
#
class dhrep::services::tomcat_tgsearch (
  $scope = undef,
  $xmx   = $dhrep::params::servicetomcat_xmx,
  $xms   = $dhrep::params::servicetomcat_xms,
) inherits dhrep::params {

  $catname      = $::dhrep::params::config['tomcat_tgsearch']['catname']
  $http_port    = $::dhrep::params::config['tomcat_tgsearch']['http_port']
  $control_port = $::dhrep::params::config['tomcat_tgsearch']['control_port']
  $jmx_port     = $::dhrep::params::config['tomcat_tgsearch']['jmx_port']
  $user         = $::dhrep::params::config['tomcat_tgsearch']['user']
  $group        = $::dhrep::params::config['tomcat_tgsearch']['group']
  $uid          = $::dhrep::params::config['tomcat_tgsearch']['uid']
  $gid          = $::dhrep::params::config['tomcat_tgsearch']['gid']

  ###
  # user, home-dir and user-tomcat
  ###
  usertomcat::create { $catname:
    user              => $user,
    group             => $group,
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
