# == Class: dhrep::services::tomcat_digilib
#
# Class to install and configure digilib tomcat.
#
class dhrep::services::tomcat_digilib (
  $scope = undef,
  $xmx   = $::dhrep::params::tomcat_digilib_xmx,
  $xms   = $::dhrep::params::tomcat_digilib_xms,
  $check_uri = 'textgrid:wtxq.0',
) inherits dhrep::params {

  $catname      = $::dhrep::params::config['tomcat_digilib']['catname']
  $http_port    = $::dhrep::params::config['tomcat_digilib']['http_port']
  $control_port = $::dhrep::params::config['tomcat_digilib']['control_port']
  $jmx_port     = $::dhrep::params::config['tomcat_digilib']['jmx_port']
  $uid          = $::dhrep::params::config['tomcat_digilib']['uid']
  $gid          = $::dhrep::params::config['tomcat_digilib']['gid']
  $depcat       = 'tomcat-crud'
  $check_url    = "http://localhost:${::dhrep::params::config['tomcat_digilib']['http_port']}/digilibservice/rest/IIIF/${check_uri}/info.json"

  ###
  # user, home-dir and user-tomcat
  ###
  usertomcat::instance { $catname:
    uid                => $uid,
    gid                => $gid,
    http_port          => $http_port,
    control_port       => $control_port,
    jmx_port           => $jmx_port,
    init_dependencies  => $depcat,
    xmx                => $xmx,
    xms                => $xms,
    telegraf_enabled   => true,
    tomcat_version     => $dhrep::params::tomcat_version,
    initd_template_loc => 'dhrep/etc/init.d/tomcat8-digilib.Debian.erb',
  }
}
