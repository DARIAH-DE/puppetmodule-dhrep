# == Class: dhrep::services::tomcat_crud
#
# Class to install and configure dhcrud or tgcrud tomcat.
#
class dhrep::services::tomcat_crud (
  $scope = undef,
  $xmx   = $::dhrep::params::tomcat_crud_xmx,
  $xms   = $::dhrep::params::tomcat_crud_xms,
) inherits dhrep::params {

  $catname      = $::dhrep::params::config['tomcat_crud']['catname']
  $http_port    = $::dhrep::params::config['tomcat_crud']['http_port']
  $control_port = $::dhrep::params::config['tomcat_crud']['control_port']
  $jmx_port     = $::dhrep::params::config['tomcat_crud']['jmx_port']
  $user         = $::dhrep::params::config['tomcat_crud']['user']
  $group        = $::dhrep::params::config['tomcat_crud']['group']
  $uid          = $::dhrep::params::config['tomcat_crud']['uid']
  $gid          = $::dhrep::params::config['tomcat_crud']['gid']

  if $scope == 'textgrid' {
    $depcat = 'wildfly'
  } else {
    $depcat = undef
  }

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
    init_dependencies    => $depcat,
    xmx                  => $xmx,
    xms                  => $xms,
    telegraf_enabled     => true,
  }
}
