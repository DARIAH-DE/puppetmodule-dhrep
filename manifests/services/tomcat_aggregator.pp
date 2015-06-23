# == Class: textgrid::services::tomcat_aggregator
#
# Class to install and configure aggregator tomcat.
#
class textgrid::services::tomcat_aggregator (
){

  $catname      = 'tomcat-aggregator'
  $http_port    = '9095'
  $control_port = '9010'
  $xmx          = '1024'
  $xms          = '128'
  $jmx_port     = '9995'

  $user         = $catname
  $group        = $catname

  ###
  # user, home-dir and user-tomcat
  ###

  textgrid::resources::servicetomcat { $catname:
    user              => $user,
    group             => $group,
    gid               => '1014',
    uid               => '1014',
    http_port         => $http_port,
    control_port      => $control_port,
    jmx_port          => $jmx_port,
    defaults_template => 'textgrid/etc/default/tomcat.erb',
  }

}