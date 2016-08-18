# == Class: dhrep::services::tomcat_oaipmh
#
# Class to install and configure oaipmh tomcat.
#
class dhrep::services::tomcat_oaipmh (
) inherits dhrep::params {

  $catname      = 'tomcat-oaipmh'
  $http_port    = '9097'
  $control_port = '9012'
  $xmx          = '1024'
  $xms          = '1024'
  $jmx_port     = '9996'
  $gid          = '1011'
  $uid          = '1011'
  $template     = 'dhrep/etc/default/tomcat.erb'

  ###
  # user, home-dir and user-tomcat
  ###
  dhrep::resources::servicetomcat { $catname:
    user              => $catname,
    group             => $catname,
    gid               => $gid,
    uid               => $uid,
    http_port         => $http_port,
    control_port      => $control_port,
    jmx_port          => $jmx_port,
    defaults_template => $template,
  }
}
