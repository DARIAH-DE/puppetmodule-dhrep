# == Class: dhrep::services::tomcat_publish
#
# Class to install and configure tgpublish or dhpublish tomcat.
#
class dhrep::services::tomcat_publish (
  $scope = undef,
  $xmx   = $::dhrep::params::tomcat_publish_xmx,
  $xms   = $::dhrep::params::tomcat_publish_xms,
) inherits dhrep::params {

  $catname      = $::dhrep::params::config['tomcat_publish']['catname']
  $http_port    = $::dhrep::params::config['tomcat_publish']['http_port']
  $control_port = $::dhrep::params::config['tomcat_publish']['control_port']
  $jmx_port     = $::dhrep::params::config['tomcat_publish']['jmx_port']
  $user         = $::dhrep::params::config['tomcat_publish']['user']
  $group        = $::dhrep::params::config['tomcat_publish']['group']
  $uid          = $::dhrep::params::config['tomcat_publish']['uid']
  $gid          = $::dhrep::params::config['tomcat_publish']['gid']
  $template     = 'dhrep/etc/default/tomcat.publish.erb'
  $depcat       = $::dhrep::params::config['tomcat_crud']['catname']

  ###
  # user, home-dir and user-tomcat
  ###
  dhrep::resources::servicetomcat { $catname:
    user              => $user,
    group             => $group,
    uid               => $uid,
    gid               => $gid,
    http_port         => $http_port,
    control_port      => $control_port,
    jmx_port          => $jmx_port,
    defaults_template => $template,
    init_dependencies => $depcat,
    xmx               => $xmx,
    xms               => $xms,
  }
}
