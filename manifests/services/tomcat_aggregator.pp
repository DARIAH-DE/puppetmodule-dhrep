# == Class: dhrep::services::tomcat_aggregator
#
# Class to install and configure aggregator tomcat.
#
class dhrep::services::tomcat_aggregator (
  $scope = undef,
  $xmx   = $dhrep::params::servicetomcat_xmx,
  $xms   = $dhrep::params::servicetomcat_xms,
) inherits dhrep::params {

  $catname      = $::dhrep::params::config['tomcat_aggregator']['catname']
  $http_port    = $::dhrep::params::config['tomcat_aggregator']['http_port']
  $control_port = $::dhrep::params::config['tomcat_aggregator']['control_port']
  $jmx_port     = $::dhrep::params::config['tomcat_aggregator']['jmx_port']
  $uid          = $::dhrep::params::config['tomcat_aggregator']['uid']
  $gid          = $::dhrep::params::config['tomcat_aggregator']['gid']

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
