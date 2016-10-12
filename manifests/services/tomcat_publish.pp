# == Class: dhrep::services::tomcat_publish
#
# Class to install and configure tgpublish or dhpublish tomcat.
#
class dhrep::services::tomcat_publish (
  $scope        = undef,
  $xmx          = $dhrep::params::tomcat_tgpublish_xmx,
  $xms          = $dhrep::params::tomcat_tgpublish_xms,
) inherits dhrep::params {

  $short        = 'tgpublish'
  $catname      = 'tomcat-tgpublish'
  $depcat       = 'tomcat-tgcrud'
  $http_port    = '9094'
  $control_port = '9009'
  $jmx_port     = '9994'
  $gid          = '29900'
  $uid          = '49628'
  $template     = "dhrep/etc/default/tomcat.${short}.erb"

  $user         = 'storage'
  $group        = 'ULSB'

  ###
  # user, home-dir and user-tomcat
  ###

  dhrep::resources::servicetomcat { $catname:
    user              => $user,
    group             => $group,
    gid               => $gid,
    uid               => $uid,
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
