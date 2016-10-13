# == Class: dhrep::params
#
# Class for textgrid and dariah scope configuration
#
class dhrep::params {

  ###
  # some global folder settings
  ###
  $confdir   = '/etc/dhrep'
  $optdir    = '/opt/dhrep'
  $logdir    = '/var/log/dhrep'
  $cachedir  = '/var/cache/dhrep'
  $vardir    = '/var/dhrep'
  $backupdir = '/var/dhrep/backups'
  $statdir   = '/var/dhrep/statistics'
  $aptdir    = '/var/dhrep/webapps'

  ###
  # crud
  ###
  $crud_name = {
    'textgrid' => 'tgcrud-webapp',
    'dariah'   => 'dhcrud-webapp'
  }
  $crud_short = {
    'textgrid' => 'tgcrud',
    'dariah'   => 'dhcrud'
  }
  $crud_version = {
    'textgrid' => 'latest',
    'dariah'   => 'latest'
  }

  ###
  # crud-public
  ###
  $crud_public_name = {
    'textgrid' => 'tgcrud-webapp-public',
    'dariah'   => 'dhcrud-webapp-public'
  }
  $crud_public_short = {
    'textgrid' => 'tgcrud-public',
    'dariah'   => 'dhcrud-public'
  }
  $crud_public_version = {
    'textgrid' => 'latest',
    'dariah'   => 'latest'
  }

  ###
  # publish
  ###
  $publish_name = {
    'textgrid' => 'kolibri-tgpublish-service',
    'dariah'   => 'kolibri-dhpublish-service'
  }
  $publish_short = {
    'textgrid' => 'tgpublish',
    'dariah'   => 'dhpublish'
  }
  $publish_version = {
    'textgrid' => 'latest',
    'dariah'   => 'latest'
  }

  ###
  # elasticsearch
  ###
  $tgelasticsearch_master_http_port    = '9202'
  $tgelasticsearch_master_tcp_port     = '9302'
  $tgelasticsearch_workhorse_http_port = '9203'
  $tgelasticsearch_workhorse_tcp_port  = '9303'

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
    'tomcat_tgsearch' => {
      'catname'      => 'tomcat-tgsearch',
      'http_port'    => '9090',
      'control_port' => '9005',
      'jmx_port'     => '9990',
      'gid'          => '1007',
      'uid'          => '1007',
    },
  }

  ###
  # memory profiles: if no hiera entry is found, default to undef, so default profile is used
  # NOTE all tomcat's except the crud, publish, and wildfly ones are using the servicetomcat's settings!
  ###
  case hiera('dhrep::mem_profile', undef) {
    'low': {
      $tgelasticsearch_es_heap_size = '64m'
      $servicetomcat_xmx            = '64m'
      $servicetomcat_xms            = '32m'
      $tomcat_crud_xmx              = '96m'
      $tomcat_crud_xms              = '32m'
      $tomcat_publish_xmx           = '128m'
      $tomcat_publish_xms           = '32m'
      $wildfly_xmx                  = '128m'
      $wildfly_xms                  = '64m'
      $wildfly_maxpermsize          = '96m'
    }
    'server': {
      $tgelasticsearch_es_heap_size = '3072m'
      $servicetomcat_xmx            = '1024m'
      $servicetomcat_xms            = '1024m'
      $tomcat_crud_xmx              = '1536m'
      $tomcat_crud_xms              = '1536m'
      $tomcat_publish_xmx           = '1536m'
      $tomcat_publish_xms           = '1536m'
      $wildfly_xmx                  = '512m'
      $wildfly_xms                  = '512m'
      $wildfly_maxpermsize          = '256m'
    }
    default: {
      $tgelasticsearch_es_heap_size = '512m'
      $servicetomcat_xmx            = '1024m'
      $servicetomcat_xms            = '128m'
      $tomcat_crud_xmx              = '1024m'
      $tomcat_crud_xms              = '128m'
      $tomcat_publish_xmx           = '1024m'
      $tomcat_publish_xms           = '128m'
      $wildfly_xmx                  = '512m'
      $wildfly_xms                  = '256m'
      $wildfly_maxpermsize          = '256m'
    }
  }
}
