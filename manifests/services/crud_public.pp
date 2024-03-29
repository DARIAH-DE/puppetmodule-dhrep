# == Class: dhrep::services::crud_public
#
# Class to install and configure public crud service.
#
class dhrep::services::crud_public (
  $location,
  $id_implementation,
  $aai_implementation,
  $data_storage_implementation,
  $idxdb_storage_implementation,
  $rdfdb_storage_implementation,
  $storage_host,
  $storage_host_public,
  $scope                        = undef,
  $publish_secret               = undef,
  $log_level                    = 'INFO',
  $use_messaging                = true,
  $pid_resolver                 = 'https://hdl.handle.net/',
  $pid_prefix                   = '21.11113',
  $doi_resolver                 = 'https://doi.org/',
  $doi_prefix                   = '10.20375',
  $doi_api_location             = 'https://api.datacite.org/',
  $orcid_resolver               = 'https://orcid.org/',
  $gnd_resolver                 = 'http://d-nb.info/gnd/',
  $publikator_location          = "https://${::fqdn}/publikator",
  # TODO? <https://ask.puppet.com/question/29749/fqdn-no-longer-valid-for-vhost-name-in-hiera-file-for-puppetlabs-apache-module>
  $link_to_documentation        = "https://${::fqdn}/doc/services/submodules/publikator/docs/index.html",
  $link_to_apidoc               = "https://${::fqdn}/doc/services",
  $link_to_faq                  = 'https://wiki.de.dariah.eu/display/publicde/FAQs+zum+DARIAH-DE+Repository',
  $name_of_contact              = 'DARIAH-DE',
  $mail_of_contact              = 'support@de.dariah.eu',
  $oaipmh_location              = "https://${::fqdn}/1.0/oaipmh/oai",
  $datacite_location            = 'https://search.datacite.org/works/',
  $digilib_location             = "https://${::fqdn}/1.0/digilib/rest/IIIF/",
  $switchboard_location         = 'https://switchboard.clarin.eu/#/dhrep/',
  $manifest_location            = "https://${::fqdn}/1.0/iiif/manifests/",
  $mirador_location             = 'https://textgridlab.org/1.0/iiif/mirador/',
  $extract_techmd               = true,
  $pid_secret                   = 'pid_secret',
  $fits_client_timeout          = 500000,
  $imprint_url                  = 'https://de.dariah.eu/impressum',
  $privpol_url                  = 'https://de.dariah.eu/privacy-policy',
  $contact_url                  = 'https://de.dariah.eu/kontakt',
  $streaming_size               = 10485760,
  $menu_header_color            = 'none',
  $badge_text                   = 'none',
  $log_config_file              = 'crud.log4j2.xml',
) inherits dhrep::params {

  $_name     = $::dhrep::params::crud_public_name[$scope]
  $_short    = $::dhrep::params::crud_public_short[$scope]
  $_version  = $::dhrep::params::crud_public_version[$scope]
  $_confdir  = $::dhrep::params::confdir
  $_logdir   = $::dhrep::params::logdir
  $_optdir   = $::dhrep::params::optdir
  $_catname  = $::dhrep::params::config['tomcat_crud']['catname']
  $_user     = $::dhrep::params::config['tomcat_crud']['user']
  $_group    = $::dhrep::params::config['tomcat_crud']['group']
  $_aptdir   = $::dhrep::params::aptdir
  $templates = "dhrep/etc/dhrep/crud-public/${scope}"

  ###
  # update apt repo and install package
  ###
  package { $_name:
    ensure  => $_version,
    require => [Exec['update_dariah_apt_repository'], Usertomcat::Instance[$_catname]],
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${_user}/${_catname}/webapps/${_short}":
    ensure  => 'link',
    target  => "${_aptdir}/${_short}",
    require => [File[ "${_confdir}/${_short}/beans.properties"], Usertomcat::Instance[$_catname]],
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
  file { "${_confdir}/${_short}/crud.properties":
    ensure  => file,
    owner   => $_user,
    group   => $_group,
    mode    => '0640',
    content => template("${templates}/crud.properties.erb"),
    require => File["${_confdir}/${_short}"],
    notify  => Service[$_catname],
  }
  file { "${_confdir}/${_short}/beans.properties":
    ensure  => file,
    owner   => $_user,
    group   => $_group,
    mode    => '0640',
    content => template("${templates}/beans.properties.erb"),
    require => File["${_confdir}/${_short}"],
  }

  ###
  # logging
  ###
  file { "${_confdir}/${_short}/${log_config_file}":
    ensure  => file,
    owner   => $_user,
    group   => $_group,
    mode    => '0640',
    content => template("${templates}/${log_config_file}.erb"),
    require => File["${_confdir}/${_short}"],
  }
  file { "${_logdir}/${_short}":
    ensure  => directory,
    owner   => $_user,
    group   => $_group,
    mode    => '0755',
    require => File[$_logdir],
  }
  logrotate::rule { $_short:
    path         => "${_logdir}/${_short}/crud.log",
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
  logrotate::rule { "${_short}_rollback":
    path         => "${_logdir}/${_short}/rollback.log",
    require      => File["${_logdir}/${_short}"],
    rotate       => 30,
    rotate_every => 'day',
    compress     => false,
    copytruncate => true,
    missingok    => true,
    ifempty      => true,
    dateext      => true,
    dateformat   => '.%Y-%m-%d',
  }

  ###
  # scope: textgrid
  ###
  if $scope == 'textgrid' {

    ###
    # cron for crud comment (scripts creation see crud.pp!) and analyse
    ###
    cron { 'crud-public-analyse':
      command => "${_optdir}/crud-analyse.pl -l ${_logdir}/${_short}/rollback.log -c ${_logdir}/${_short}/logcomments.log > /dev/null 2>&1",
      user    => $_user,
      minute  => '2-59/5',
    }

    ###
    # nrpe for tgcrud_public
    ###
    nrpe::plugin { 'check_rollback_tgcrud_public':
      plugin     => 'crud-analyse.pl',
      args       => "-n -l ${_logdir}/${_short}/rollback.log",
      libexecdir => $_optdir,
    }
  }
}
