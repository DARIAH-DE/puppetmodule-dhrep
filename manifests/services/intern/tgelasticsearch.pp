# == Class: textgrid::services::intern::tgelasticsearch
#
# Class to install and configure elasticsearch
# 
# === Parameters
#
# [*cluster_name*]
#   name of elastic search cluster
#
# [*master_http_port*]
#   elastic search http port (masternode)
#
# [*master_tcp_port*]
#   elastic search tcp transport port (masternode)
#
class textgrid::services::intern::tgelasticsearch (
  $cluster_name,
  $master_http_port = '9202',
  $master_tcp_port = '9302',
) {

  # read docs at https://github.com/elasticsearch/puppet-elasticsearch/tree/master

  class { 'elasticsearch':
    #manage_repo  => true,
    #repo_version => '1.0',
    #autoupgrade  => true,
    package_url => 'https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.0.3.deb',
    config      => {
      'cluster.name' => $cluster_name,
      'network.host' => '127.0.0.1',
    },
    java_install => false,
  }

  elasticsearch::instance { 'masternode':
    config => {
      'node.master'        => 'true',
      'node.data'          => 'true',
      'http.port'          => $master_http_port,
      'transport.tcp.port' => $master_tcp_port,
    }
  }

  elasticsearch::instance { 'workhorse':
    config => {
      'node.master'        => 'false',
      'node.data'          => 'true',
      'http.port'          => '9203',
      'transport.tcp.port' => '9303',
    }
  }

}
