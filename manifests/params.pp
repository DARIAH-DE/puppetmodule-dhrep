# == Class: dhrep::params
#
# Class for textgrid and dariah scope configuration
#
class dhrep::params {

# do we still need this somewhere?!
#  $maven_repository = 'http://dev.dariah.eu/nexus/content/repositories/releases/'

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

  ###
  # publish
  ###
  $publish_name = {
    'textgrid' => 'kolibri-tgpublish-service',
    'dariah'   => 'kolibri-dhpublish-service'
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
  # FIXME Machen wir später für alle relevanten config parameter!
  # Zugriff dann per $::dhrep::params::config['tomcat_tgcrud']['catname']
  ###
  $config = {
    'tomcat_crud' => {
      'catname'      => 'tomcat-crud',
      'http_port'    => '9093',
      'control_port' => '9008',
      'jmx_port'     => '9993',
      'gid'          => '29900',
      'uid'          => '49628',
    },
    'tomcat_publish' => {
      'catname'      => 'tomcat-publish',
      'http_port'    => '9094',
      'control_port' => '9009',
      'jmx_port'     => '9994',
      'gid'          => '29900',
      'uid'          => '49628',
    },
  }

  ###
  # memory profiles: if no hiera entry is found, default to undef, so default profile is used)
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
