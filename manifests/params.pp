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



  $config = {
    'oaipmh'    => {
      'catname'   => 'tomcat-oaipmh',
      'http_port' => 9097,
    },
    'pid'             => {
      'pid_endpoint' => 'http://pid.gwdg.de',
    }
  }


}

