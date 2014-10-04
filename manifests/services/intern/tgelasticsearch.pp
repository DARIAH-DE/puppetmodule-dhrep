class textgrid::services::intern::tgelasticsearch {

  # read docs at https://github.com/elasticsearch/puppet-elasticsearch/tree/master

  class { 'elasticsearch':
    #manage_repo  => true,
    #repo_version => '1.0',
    #autoupgrade  => true,
    package_url => 'https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.0.3.deb',
    config      => { 
      'cluster.name' => 'tg-dev1-test-instance',
      'network.host' => '127.0.0.1',
    },
    java_install => false,
  }

  elasticsearch::instance { 'masternode':
    config => { 
      'node.master'        => 'true',
      'node.data'          => 'true',
      'http.port'          => '9202',
      'transport.tcp.port' => '9302',
    }
  }

  elasticsearch::instance { 'workhorse':  
    config      => { 
      'node.master'        => 'false',
      'node.data'          => 'true',
      'http.port'          => '9203',
      'transport.tcp.port' => '9303',
    }
  }

}
