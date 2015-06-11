# == Class: textgrid::services::oaipmh
#
# Class to install and configure oaipmh
#
class textgrid::services::oaipmh (
  $scope          = 'textgrid',
  $short          = 'tgoaipmh',
  $oaipmh_name    = 'oaipmh-webapp',
  $oaipmh_version = '1.0-SNAPSHOT',
){

  include textgrid::services::intern::tgelasticsearch
  include textgrid::services::tomcat_oaipmh
  
  $catname = $textgrid::services::tomcat_oaipmh::catname
  $user    = $textgrid::services::tomcat_oaipmh::user
  $group   = $textgrid::services::tomcat_oaipmh::group
 
  ###
  # config
  ###

  file { "/etc/${scope}/${short}":
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { "/etc/${scope}/${short}/oaipmh.properties":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("${scope}/etc/${scope}/${short}/oaipmh.properties.erb"),
    require => File["/etc/${scope}/${short}"],
  }

  ###
  # logging
  ###

  file { "/etc/${scope}/${short}/log4j.oaipmh.properties":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("${scope}/etc/${scope}/${short}/log4j.oaipmh.properties.erb"),
    require => File["/etc/${scope}/${short}"],
  }

  file { "/var/log/${scope}/${short}":
    ensure  => directory,
    owner   => root,
    group   => $group,
    mode    => '0755',
    require => File["/var/log/${scope}"],
  }

}
