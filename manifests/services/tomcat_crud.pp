# == Class: dhrep::services::tomcat_crud
#
# Class to install and configure dhcrud or tgcrud tomcat.
#
class dhrep::services::tomcat_crud (
  $scope = undef,
  $xmx   = $::dhrep::params::tomcat_crud_xmx,
  $xms   = $::dhrep::params::tomcat_crud_xms,
) inherits dhrep::params {

  $_catname      = $::dhrep::params::catname
  $_http_port    = $::dhrep::params::http_port
  $_control_port = $::dhrep::params::control_port
  $_jmx_port     = $::dhrep::params::jmx_port
  $_gid          = $::dhrep::params::gid
  $_uid          = $::dhrep::params::uid

  $template     = 'dhrep/etc/default/tomcat.crud.erb'
  $depcat       = 'wildfly'
  $user         = 'storage'
  $group        = 'storage'

  ###
  # user, home-dir and user-tomcat
  ###
  dhrep::resources::servicetomcat { $_catname:
    user              => $user,
    group             => $group,
    gid               => $_gid,
    uid               => $_uid,
    http_port         => $_http_port,
    control_port      => $_control_port,
    jmx_port          => $_jmx_port,
    defaults_template => $template,
    init_dependencies => $depcat,
    xmx               => $xmx,
    xms               => $xms,
    require           => Service[$depcat],
  }
}
