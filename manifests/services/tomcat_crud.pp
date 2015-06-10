# == Class: textgrid::services::tomcat_crud
#
# Class to install and configure dhcrud's or tgcrud's tomcat.
#
class textgrid::services::tomcat_crud (
){

  $scope        = 'textgrid'
  $short        = 'tgcrud'
  $catname      = 'tomcat-tgcrud'
  $http_port    = '9093'
  $control_port = '9008'
  $xmx          = '1024'
  $xms          = '128'
  $jmx_port     = '9993'

  $user         = $scope
  $group        = 'ULSB'
  
  ###
  # user, home-dir and user-tomcat
  ###
  textgrid::resources::servicetomcat { $catname:
    user              => $user,
    group             => $group,
    gid               => '29900',
    uid               => '49628',
    http_port         => $http_port,
    control_port      => $control_port,
    jmx_port          => $jmx_port,
    defaults_template => "${scope}/etc/default/tomcat.${short}.erb",
    init_dependencies => 'wildfly',
    require           => Service['wildfly'],
  }

}
