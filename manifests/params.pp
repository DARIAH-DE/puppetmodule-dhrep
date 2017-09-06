# == Class: dhrep::params
#
# Class for textgrid and dariah scope configuration
#
class dhrep::params {

  ###
  # some global settings
  ###
  $aptdir     = '/var/dhrep/webapps'
  $backupdir  = '/var/dhrep/backups'
  $cachedir   = '/var/cache/dhrep'
  $confdir    = '/etc/dhrep'
  $logdir     = '/var/log/dhrep'
  $optdir     = '/opt/dhrep'
  $statdir    = '/var/dhrep/statistics'
  $vardir     = '/var/dhrep'

  ###
  # crud
  ###
  $crud_name = {
    'textgrid' => 'tgcrud-webapp',
    'dariah'   => 'dhcrud-webapp',
  }
  $crud_short = {
    'textgrid' => 'tgcrud',
    'dariah'   => 'dhcrud',
  }
  $crud_version = {
    'textgrid' => 'latest',
    'dariah'   => 'latest',
  }

  ###
  # crud-public
  ###
  $crud_public_name = {
    'textgrid' => 'tgcrud-webapp-public',
    'dariah'   => 'dhcrud-webapp-public',
  }
  $crud_public_short = {
    'textgrid' => 'tgcrud-public',
    'dariah'   => 'dhcrud-public',
  }
  $crud_public_version = {
    'textgrid' => 'latest',
    'dariah'   => 'latest',
  }

  ###
  # publish
  ###
  $publish_name = {
    'textgrid' => 'kolibri-tgpublish-service',
    'dariah'   => 'kolibri-dhpublish-service',
  }
  $publish_short = {
    'textgrid' => 'tgpublish',
    'dariah'   => 'dhpublish',
  }
  $publish_version = {
    'textgrid' => 'latest',
    'dariah'   => 'latest',
  }

  ###
  # pid
  ###
  $pid_name = {
    'textgrid' => 'pid-webapp',
    'dariah'   => 'pid-webapp',
  }
  $pid_short = {
    'textgrid' => 'tgpid',
    'dariah'   => 'dhpid',
  }
  $pid_version = {
    'textgrid' => 'latest',
    'dariah'   => 'latest',
  }

  ###
  # oaipmh
  ###
  $oaipmh_name = {
    'textgrid' => 'oaipmh-webapp',
    'dariah'   => 'oaipmh-webapp',
  }
  $oaipmh_version = {
    'textgrid' => 'latest',
    'dariah'   => 'latest',
  }

  ###
  # publikator
  ###
  $publikator_name = {
    'dariah'   => 'publikator-webapp',
  }
  $publikator_version = {
    'dariah'   => 'latest',
  }

  ###
  # elasticsearch
  ###
  $elasticsearch_master_http_port    = '9202'
  $elasticsearch_master_tcp_port     = '9302'
  $elasticsearch_workhorse_http_port = '9203'
  $elasticsearch_workhorse_tcp_port  = '9303'

  ###
  # more specific config settings
  ###
  $config = {
    'tomcat_aggregator' => {
      'catname'      => 'tomcat-aggregator',
      'http_port'    => '9095',
      'control_port' => '9010',
      'jmx_port'     => '9995',
      'gid'          => '1014',
      'uid'          => '1014',
    },
    'tomcat_crud' => {
      'catname'      => 'tomcat-crud',
      'http_port'    => '9093',
      'control_port' => '9008',
      'jmx_port'     => '9993',
      'gid'          => '29900',
      'uid'          => '49628',
      'user'         => 'storage',
      'group'        => 'ULSB',
    },
    'tomcat_digilib' => {
      'catname'      => 'tomcat-digilib',
      'http_port'    => '9092',
      'control_port' => '9007',
      'jmx_port'     => '9992',
      'gid'          => '1009',
      'uid'          => '1009',
    },
    'tomcat_digilib2' => {
      'catname'      => 'tomcat-digilib2',
      'http_port'    => '9192',
      'control_port' => '9107',
      'jmx_port'     => '9912',
    },
    'tomcat_fits' => {
      'catname'      => 'tomcat-fits',
      'http_port'    => '9098',
      'control_port' => '9013',
      'jmx_port'     => '9998',
      'gid'          => '1012',
      'uid'          => '1012',
    },
    'tomcat_oaipmh' => {
      'catname'      => 'tomcat-oaipmh',
      'http_port'    => '9097',
      'control_port' => '9012',
      'jmx_port'     => '9996',
      'gid'          => '1011',
      'uid'          => '1011',
    },
    'tomcat_publish' => {
      'catname'      => 'tomcat-publish',
      'http_port'    => '9094',
      'control_port' => '9009',
      'jmx_port'     => '9994',
      'gid'          => '29900',
      'uid'          => '49628',
      'user'         => 'storage',
      'group'        => 'ULSB',
    },
    'tomcat_sesame' => {
      'catname'      => 'tomcat-sesame',
      'http_port'    => '9091',
      'control_port' => '9006',
      'jmx_port'     => '9991',
      'gid'          => '1008',
      'uid'          => '1008',
    },
    'tomcat_tgsearch' => {
      'catname'      => 'tomcat-tgsearch',
      'http_port'    => '9090',
      'control_port' => '9005',
      'jmx_port'     => '9990',
      'gid'          => '1007',
      'uid'          => '1007',
    },
    'tomcat_publikator' => {
      'catname'      => 'tomcat-publikator',
      'http_port'    => '9099',
      'control_port' => '9014',
      'jmx_port'     => '9999',
      'gid'          => '1015',
      'uid'          => '1015',
    },
    'tomcat_pid' => {
      'catname'      => 'tomcat-pid',
      'http_port'    => '9100',
      'control_port' => '9015',
      'jmx_port'     => '10000',
      'gid'          => '1016',
      'uid'          => '1016',
    },
  }

  ###
  # memory profiles: if no hiera entry is found, default to undef, so default
  # profile is used
  # NOTE all tomcats except the crud, publish, and wildfly ones are using the
  # servicetomcat's settings!
  ###
  case hiera('dhrep::mem_profile', undef) {
    'low': {
      $elasticsearch_es_heap_size = '64m'
      $servicetomcat_xmx          = '64m'
      $servicetomcat_xms          = '32m'
      $tomcat_crud_xmx            = '96m'
      $tomcat_crud_xms            = '32m'
      $tomcat_publish_xmx         = '128m'
      $tomcat_publish_xms         = '32m'
      $wildfly_xmx                = '128m'
      $wildfly_xms                = '64m'
      $wildfly_maxpermsize        = '96m'
      $tomcat_oaipmh_xmx          = '64m'
      $tomcat_oaipmh_xms          = '32m'
      $tomcat_publikator_xmx      = '64m'
      $tomcat_publikator_xms      = '32m'
      $tomcat_fits_xmx            = '64m'
      $tomcat_fits_xms            = '32m'
      $tomcat_sesame_xmx          = '64m'
      $tomcat_sesame_xms          = '32m'
      $tomcat_digilib_xmx         = '64m'
      $tomcat_digilib_xms         = '32m'
    }
    'server': {
      $elasticsearch_es_heap_size = '3072m'
      $servicetomcat_xmx          = '1024m'
      $servicetomcat_xms          = '1024m'
      $tomcat_crud_xmx            = '1792m'
      $tomcat_crud_xms            = '1792m'
      $tomcat_publish_xmx         = '1024m'
      $tomcat_publish_xms         = '1024m'
      $wildfly_xmx                = '384m'
      $wildfly_xms                = '384m'
      $wildfly_maxpermsize        = '256m'
      $tomcat_oaipmh_xmx          = '512m'
      $tomcat_oaipmh_xms          = '512m'
      $tomcat_publikator_xmx      = '512m'
      $tomcat_publikator_xms      = '512m'
      $tomcat_fits_xmx            = '512m'
      $tomcat_fits_xms            = '512m'
      $tomcat_sesame_xmx          = '768m'
      $tomcat_sesame_xms          = '768m'
      $tomcat_digilib_xmx         = '1280m'
      $tomcat_digilib_xms         = '1280m'
    }
    default: {
      $elasticsearch_es_heap_size = '512m'
      $servicetomcat_xmx          = '1024m'
      $servicetomcat_xms          = '32m'
      $tomcat_crud_xmx            = '1024m'
      $tomcat_crud_xms            = '32m'
      $tomcat_publish_xmx         = '1024m'
      $tomcat_publish_xms         = '32m'
      $wildfly_xmx                = '384m'
      $wildfly_xms                = '32m'
      $wildfly_maxpermsize        = '256m'
      $tomcat_oaipmh_xmx          = '512m'
      $tomcat_oaipmh_xms          = '32m'
      $tomcat_publikator_xmx      = '512m'
      $tomcat_publikator_xms      = '32m'
      $tomcat_fits_xmx            = '512m'
      $tomcat_fits_xms            = '32m'
      $tomcat_sesame_xmx          = '256m'
      $tomcat_sesame_xms          = '32m'
      $tomcat_digilib_xmx         = '512m'
      $tomcat_digilib_xms         = '32m'
    }
  }
}
