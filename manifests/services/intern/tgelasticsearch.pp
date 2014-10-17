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
  $es_version = '1.0.3',
  $attachments_plugin_version = '2.0.0',
) {

  # read docs at https://github.com/elasticsearch/puppet-elasticsearch/tree/master

  class { 'elasticsearch':
    #manage_repo  => true,
    #repo_version => '1.0',
    #autoupgrade  => true,
    package_url => "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${es_version}.deb",
    config      => {
      'cluster.name' => $cluster_name,
# es is unreachable with following option, because it is bound to 10.0.2.14 on vagrant (why?)
#      'network.host' => '127.0.0.1',
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

  elasticsearch::plugin{"elasticsearch/elasticsearch-mapper-attachments/${attachments_plugin_version}":
    module_dir => 'mapper-attachments',
    instances  => ['masternode', 'workhorse'],
  }


  # run only once
  unless $tgelastic_repos_initialized {

    # clone commons repo, which contains shell scripts to create textgrid elastic search indizes
    exec { 'git_clone_tgcommon':
      path    => ['/usr/bin','/bin','/usr/sbin'],
      command => 'git clone git://git.projects.gwdg.de/common.git /usr/local/src/tgcommon-git',
      creates => '/usr/local/src/tgcommon-git',
      require => Package['git'],
    }
    ->
    exec { 'create_public_es_index':
#      path    => ['/usr/bin','/bin','/usr/sbin', '/usr/local/src/tgcommon-git/esutils/tools/createIndex/'],
      path    => ['/usr/bin','/bin','/usr/sbin'],
      cwd     => '/usr/local/src/tgcommon-git/esutils/tools/createIndex/',
      command => "/usr/local/src/tgcommon-git/esutils/tools/createIndex/createAllPublic.sh localhost:${master_http_port}",
      require => [Package['curl']],
    }
    ->
    exec { 'create_nonpublic_es_index':
#      path    => ['/usr/bin','/bin','/usr/sbin', '/usr/local/src/tgcommon-git/esutils/tools/createIndex/'],
      path    => ['/usr/bin','/bin','/usr/sbin'],
      cwd     => '/usr/local/src/tgcommon-git/esutils/tools/createIndex/',
      command => "/usr/local/src/tgcommon-git/esutils/tools/createIndex/createAllNonpublic.sh localhost:${master_http_port}",
      require => [Package['curl']],
    }
    ->
    file {'/etc/facter/facts.d/tgelastic_repos_initialized.txt':
      content => "tgelastic_repos_initialized=true",
    }
  }

}
