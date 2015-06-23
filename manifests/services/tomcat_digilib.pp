# == Class: textgrid::services::tomcat_digilib
#
# Class to install and configure digilib tomcat.
#
class textgrid::services::tomcat_digilib (
){

  $catname      = 'tomcat-iiif'
  $http_port    = '9092'
  $control_port = '9007'
  $xmx          = '1024'
  $xms          = '128'
  $jmx_port     = '9992'

  $user         = $catname
  $group        = $catname

  ###
  # user, home-dir and user-tomcat
  ###

  textgrid::resources::servicetomcat { $catname:
    user              => $user,
    group             => $group,
    gid               => '1009',
    uid               => '1009',
    http_port         => $http_port,
    control_port      => $control_port,
    jmx_port          => $jmx_port,
    defaults_template => 'textgrid/etc/default/tomcat.erb',
  }

}
