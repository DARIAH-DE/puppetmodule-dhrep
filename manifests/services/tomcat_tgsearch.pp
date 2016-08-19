# == Class: dhrep::services::tomcat_tgsearch
#
# Class to install and configure tgsearch tomcat.
#
class dhrep::services::tomcat_tgsearch (
  $scope = undef,
) inherits dhrep::params {

  $catname      = $::dhrep::params::config['tomcat_tgsearch']['catname']
  $http_port    = $::dhrep::params::config['tomcat_tgsearch']['http_port']
  $control_port = $::dhrep::params::config['tomcat_tgsearch']['control_port']
  $jmx_port     = $::dhrep::params::config['tomcat_tgsearch']['jmx_port']
  $gid          = $::dhrep::params::config['tomcat_tgsearch']['gid']
  $uid          = $::dhrep::params::config['tomcat_tgsearch']['uid']
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
