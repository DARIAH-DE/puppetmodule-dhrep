# == Class: dhrep::services::tomcat_pid
#
# Class to install and configure pid service tomcat.
#
class dhrep::services::tomcat_pid (
  $scope = undef,
  $xmx   = $dhrep::params::servicetomcat_xmx,
  $xms   = $dhrep::params::servicetomcat_xms,
) inherits dhrep::params {

  $catname      = $::dhrep::params::config['tomcat_pid']['catname']
  $http_port    = $::dhrep::params::config['tomcat_pid']['http_port']
  $control_port = $::dhrep::params::config['tomcat_pid']['control_port']
  $jmx_port     = $::dhrep::params::config['tomcat_pid']['jmx_port']
  $uid          = $::dhrep::params::config['tomcat_pid']['uid']
  $gid          = $::dhrep::params::config['tomcat_pid']['gid']

  ###
  # user, home-dir and user-tomcat
  ###
  usertomcat::instance { $catname:
    uid                  => $uid,
    gid                  => $gid,
    http_port            => $http_port,
    control_port         => $control_port,
    jmx_port             => $jmx_port,
    additional_java_opts => '-Dfile.encoding=UTF-8',
    xmx                  => $xmx,
    xms                  => $xms,
    telegraf_enabled     => true,
  }
}
