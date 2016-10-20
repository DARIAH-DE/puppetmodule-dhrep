# == Class: dhrep::services::tomcat_fits
#
# Class to install and configure the fits' tomcat.
#
class dhrep::services::tomcat_fits (
) inherits dhrep::params {

  $catname      = $::dhrep::params::config['tomcat_fits']['catname']
  $http_port    = $::dhrep::params::config['tomcat_fits']['http_port']
  $control_port = $::dhrep::params::config['tomcat_fits']['control_port']
  $jmx_port     = $::dhrep::params::config['tomcat_fits']['jmx_port']
  $user         = $catname
  $group        = $catname
  $uid          = $::dhrep::params::config['tomcat_fits']['uid']
  $gid          = $::dhrep::params::config['tomcat_fits']['gid']
  $template     = 'dhrep/etc/default/tomcat.erb'

  ###
  # user, home-dir and user-tomcat
  ###
  dhrep::resources::servicetomcat { $catname:
    user              => $user,
    group             => $fgroup,
    uid               => $uid,
    gid               => $gid,
    http_port         => $http_port,
    control_port      => $control_port,
    jmx_port          => $jmx_port,
    defaults_template => $template,
  }
}
