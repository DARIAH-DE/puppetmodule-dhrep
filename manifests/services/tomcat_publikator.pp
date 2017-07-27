# == Class: dhrep::services::tomcat_publikator
#
# Class to install and configure THE PUBLIKATOR tomcat.
#
class dhrep::services::tomcat_publikator (
  $scope = undef,
  $xmx   = $dhrep::params::servicetomcat_xmx,
  $xms   = $dhrep::params::servicetomcat_xms,
) inherits dhrep::params {

  $catname      = $::dhrep::params::config['tomcat_publikator']['catname']
  $http_port    = $::dhrep::params::config['tomcat_publikator']['http_port']
  $control_port = $::dhrep::params::config['tomcat_publikator']['control_port']
  $jmx_port     = $::dhrep::params::config['tomcat_publikator']['jmx_port']
  $user         = $::dhrep::params::config['tomcat_publikator']['user']
  $group        = $::dhrep::params::config['tomcat_publikator']['group']
  $uid          = $::dhrep::params::config['tomcat_publikator']['uid']
  $gid          = $::dhrep::params::config['tomcat_publikator']['gid']

  ###
  # user, home-dir and user-tomcat
  ###
  usertomcat::instance { $catname:
    user                 => $user,
    group                => $group,
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
