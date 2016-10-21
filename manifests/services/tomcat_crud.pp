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
  $template     = 'dhrep/etc/default/tomcat.crud.erb'
  $depcat       = 'wildfly'

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
    require           => Service[$depcat],
  }
}
