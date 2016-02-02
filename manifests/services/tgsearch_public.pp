# == Class: dhrep::services::tgsearch_public
#
# Class to install and configure tgsearch public.
#
class dhrep::services::tgsearch_public (
  $scope            = 'textgrid',
  $short            = 'tgsearch-public',
  $tgsearch_name    = 'tgsearch-public-webapp',
  $tgsearch_version = 'latest',
) {

  package { $tgsearch_name:
    ensure  => $tgsearch_version,
    require => Exec['update_dariah_apt_repository'],
  }

  include dhrep::services::tomcat_tgsearch

  $catname = $dhrep::services::tomcat_tgsearch::catname
  $user    = $dhrep::services::tomcat_tgsearch::user
  $group   = $dhrep::services::tomcat_tgsearch::group

  ###
  # config
  ###

#  file { "/etc/textgrid/tgsearch":
#    ensure => directory,
#    owner  => root,
#    group  => root,
#    mode   => '0755',
#  }

  file { "/etc/textgrid/tgsearch/tgsearch-public.properties":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("dhrep/etc/textgrid/${short}/tgsearch.properties.erb"),
    require => File["/etc/textgrid/tgsearch"],
    notify  => Service['tomcat-tgsearch'],
  }

  file { "/etc/textgrid/tgsearch/log4.public.properties":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("dhrep/etc/textgrid/${short}/log4j.properties.erb"),
    require => File["/etc/textgrid/tgsearch"],
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###

  file { "/home/${catname}/${catname}/webapps/${short}": 
    ensure => 'link',
    target => "/var/${scope}/webapps/tgsearch-public", 
  }

}
