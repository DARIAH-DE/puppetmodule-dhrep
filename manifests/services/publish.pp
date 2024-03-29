# == Class: dhrep::services::publish
#
# Class to install and configure publish service.
#
class dhrep::services::publish (
  $scope                                = undef,
  $log_level                            = 'INFO',
  $fake_pids                            = false,
  $pid_secret                           = 'pidSecret',
  $publish_secret                       = 'publishSecret',
  $storage_host                         = 'https://de.dariah.eu/storage/',
  $redis_hostname                       = 'localhost',
  $redis_port                           = 6379,
  $redis_max_parallel                   = 100,
  $redis_database_no                    = 1,
  $fail_if_already_published_on_publish = true,
  $error_timeout                        = 3600000,
  $dhpid_client_timeout                 = 60000,
  $dhcrud_client_timeout                = 600000,
  $cr_endpoint                          = 'https://repository.de.dariah.eu/colreg-ui/',
  $cr_client_timeout                    = 5000,
  $cr_submit_draft_path                 = '/api/collections/submitAndPublish',
  $cr_oai_path                          = 'oaipmh',
  $cr_import_key                        = 'crImportKey',
  $default_process_starter              = 'dariahde.publish.DHPublish',
  $policies_file                        = 'policies.xml',
  $maintenance                          = false,
) inherits dhrep::params {

  include dhrep::services::tomcat_publish

  $_name     = $::dhrep::params::publish_name[$scope]
  $_short    = $::dhrep::params::publish_short[$scope]
  $_version  = $::dhrep::params::publish_version[$scope]
  $_confdir  = $::dhrep::params::confdir
  $_logdir   = $::dhrep::params::logdir
  $_catname  = $::dhrep::services::tomcat_publish::catname
  $_user     = $::dhrep::services::tomcat_publish::user
  $_group    = $::dhrep::services::tomcat_publish::group
  $_aptdir   = $::dhrep::params::aptdir
  $templates = 'dhrep/etc/dhrep/publish'
  $crud_port = $::dhrep::params::config['tomcat_crud']['http_port'];
  $pid_port  = $::dhrep::params::config['tomcat_pid']['http_port'];

  ###
  # update apt repo and install package
  ###
  package { $_name:
    ensure  => $_version,
    require => [Exec['update_dariah_apt_repository'],Usertomcat::Instance[$_catname]],
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${_user}/${_catname}/webapps/${_short}":
    ensure  => 'link',
    target  => "${_aptdir}/${_short}",
    require => [File["${_confdir}/${_short}/beans.properties"],Usertomcat::Instance[$_catname]],
  }

  ###
  # config
  ###
  file { "${_confdir}/${_short}":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { "${_confdir}/${_short}/config.xml":
    ensure  => file,
    owner   => $_user,
    group   => $_group,
    mode    => '0640',
    content => template("${templates}/${scope}/config.xml.erb"),
    require => File["${_confdir}/${_short}"],
    notify  => Service[$_catname],
  }
  file { "${_confdir}/${_short}/beans.properties":
    ensure  => file,
    owner   => $_user,
    group   => $_group,
    mode    => '0640',
    content => template("${templates}/${scope}/beans.properties.erb"),
    require => File["${_confdir}/${_short}"],
  }
  file { "${_confdir}/${_short}/${policies_file}":
    ensure  => file,
    owner   => $_user,
    group   => $_group,
    mode    => '0640',
    content => template("${templates}/${scope}/${policies_file}.erb"),
    require => File["${_confdir}/${_short}"],
    notify  => Service[$_catname],
  }
  file { "${_confdir}/${_short}/mets_template.xml":
    ensure  => file,
    owner   => $_user,
    group   => $_group,
    mode    => '0640',
    content => template("${templates}/mets_template.xml.erb"),
    require => File["${_confdir}/${_short}"],
    notify  => Service[$_catname],
  }
  file { "${_confdir}/${_short}/map_dias2jhove.xml":
    ensure  => file,
    owner   => $_user,
    group   => $_group,
    mode    => '0640',
    content => template("${templates}/map_dias2jhove.xml.erb"),
    require => File["${_confdir}/${_short}"],
    notify  => Service[$_catname],
  }
  file { "${_confdir}/${_short}/dias_formatregistry.xml":
    ensure  => file,
    owner   => $_user,
    group   => $_group,
    mode    => '0640',
    content => template("${templates}/dias_formatregistry.xml.erb"),
    require => File["${_confdir}/${_short}"],
    notify  => Service[$_catname],
  }

  ###
  # temp, dest, and work dir
  ###
  file { "${_confdir}/${_short}/temp":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["${_confdir}/${_short}"],
  }
  file { "${_confdir}/${_short}/dest":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["${_confdir}/${_short}"],
  }
  file { "${_confdir}/${_short}/work":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["${_confdir}/${_short}"],
  }

  ###
  # logging
  ###
  file { "${_logdir}/${_short}":
    ensure  => directory,
    owner   => $_user,
    group   => $_group,
    mode    => '0755',
    require => File[$_logdir],
  }

  logrotate::rule { $_short:
    path         => "${_logdir}/${_short}/kolibri.log",
    require      => File["${_logdir}/${_short}"],
    rotate       => 30,
    rotate_every => 'day',
    compress     => true,
    copytruncate => true,
    missingok    => true,
    ifempty      => true,
    dateext      => true,
    dateformat   => '.%Y-%m-%d',
  }

}
