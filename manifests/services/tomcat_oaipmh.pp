# == Class: textgrid::services::tomcat_oaipmh
#
# Class to install and configure oaipmh's tomcat.
#
class textgrid::services::tomcat_oaipmh (
){

  include textgrid::services::intern::tgelasticsearch

  $catname      = 'tomcat-oaipmh'
  $http_port    = '9097'
  $control_port = '9012'
  $xmx          = '1024'
  $xms          = '128'
  $jmx_port     = '9996'

  $user         = $catname
  $group        = $catname

  ###
  # user, home-dir and user-tomcat
  ###
  textgrid::resources::servicetomcat { $catname:
    user              => $user,
    group             => $group,
    gid               => '1011',
    uid               => '1011',
    http_port         => $http_port,
    control_port      => $control_port,
    jmx_port          => $jmx_port,
    defaults_template => 'textgrid/etc/default/tomcat.erb',
  }

}
