# == Class: dhrep::services::tomcat_oaipmh
#
# Class to install and configure oaipmh tomcat.
#
class dhrep::services::tomcat_oaipmh (
) inherits dhrep::params {

  $catname      = $::dhrep::params::config['tomcat_oaipmh']['catname']
  $http_port    = $::dhrep::params::config['tomcat_oaipmh']['http_port']
  $control_port = $::dhrep::params::config['tomcat_oaipmh']['control_port']
  $jmx_port     = $::dhrep::params::config['tomcat_oaipmh']['jmx_port']
  $user         = $catname
  $group        = $catname
  $uid          = $::dhrep::params::config['tomcat_oaipmh']['uid']
  $gid          = $::dhrep::params::config['tomcat_oaipmh']['gid']
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
