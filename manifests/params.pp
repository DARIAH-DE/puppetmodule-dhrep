# Params

class dhrep::params {

  $maven_repository = 'http://dev.dariah.eu/nexus/content/repositories/releases/'

  $logdir = {
    'textgrid' => '/var/log/textgrid',
    'dariah'   => '/var/log/dariah'
  }
  $confdir = {
    'textgrid' => '/etc/textgrid',
    'dariah'   => '/etc/dariah'
  }

  $crud_name = {
    'textgrid' => 'tgcrud-webapp',
    'dariah'   => 'dhcrud-webapp'
  }
  $crud_public_name = {
    'textgrid' => 'tgcrud-webapp-public',
    'dariah'   => 'dhcrud-webapp-public'
  }

  $publish_name = {
    'textgrid' => 'kolibri-tgpublish-service',
    'dariah'   => 'kolibri-dhpublish-service'
  }

  $tgelasticsearch_master_http_port    = '9202'
  $tgelasticsearch_master_tcp_port     = '9302'
  $tgelasticsearch_workhorse_http_port = '9203'
  $tgelasticsearch_workhorse_tcp_port  = '9303'

  $config = {
    'oaipmh'    => {
      'catname'   => 'tomcat-oaipmh',
      'http_port' => 9097,
    },
    'pid'             => {
      'pid_endpoint' => 'http://pid.gwdg.de',
    }
  }

  # memory profiles
  # if no hiera entry is found, default to undef, so default profile is used
  case hiera('dhrep::mem_profile', undef) {
    'low': {
      $tgelasticsearch_es_heap_size        = '64m'
      $servicetomcat_xmx                   = '64m'
      $servicetomcat_xms                   = '32m'
      $tomcat_tgcrud_xmx                   = '96m'
      $tomcat_tgcrud_xms                   = '32m'
      $tomcat_tgpublish_xmx                = '128m'
      $tomcat_tgpublish_xms                = '32m'
      $wildfly_xmx                         = '128m'
      $wildfly_xms                         = '64m'
      $wildfly_maxpermsize                 = '96m'
    }
    'server': {
      $tgelasticsearch_es_heap_size        = '3072m'
      $servicetomcat_xmx                   = '1024m'
      $servicetomcat_xms                   = '1024m'
      $tomcat_tgcrud_xmx                   = '1536m'
      $tomcat_tgcrud_xms                   = '1536m'
      $tomcat_tgpublish_xmx                = '1536m'
      $tomcat_tgpublish_xms                = '1536m'
      $wildfly_xmx                         = '512m'
      $wildfly_xms                         = '512m'
      $wildfly_maxpermsize                 = '256m'
    }
    default: {
      $tgelasticsearch_es_heap_size        = '512m'
      $servicetomcat_xmx                   = '1024m'
      $servicetomcat_xms                   = '128m'
      $tomcat_tgcrud_xmx                   = '1024m'
      $tomcat_tgcrud_xms                   = '128m'
      $tomcat_tgpublish_xmx                = '1024m'
      $tomcat_tgpublish_xms                = '128m'
      $wildfly_xmx                         = '512m'
      $wildfly_xms                         = '256m'
      $wildfly_maxpermsize                 = '256m'
    }
  }

}
