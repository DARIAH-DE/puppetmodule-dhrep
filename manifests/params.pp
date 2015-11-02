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

  $dhrep::params::confdir[$scope]

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

