# == Class: dhrep::services::intern::tgelasticsearch
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
class dhrep::services::intern::tgelasticsearch (
  $scope                      = undef,
  $cluster_name               = undef,
  $repo_version               = '1.7',
  $elasticsearch_version      = '1.7.0',
  $attachments_plugin_version = '2.7.0',
  $highlighter_plugin_version = '1.7.0',
  $es_heap_size               = $dhrep::params::tgelasticsearch_es_heap_size,
) inherits dhrep::params {

  package {
    'python-pip': ensure => present,
  }

  # read docs at https://github.com/elasticsearch/puppet-elasticsearch/tree/master

  class { 'elasticsearch':
    manage_repo   => true,
    version       => $elasticsearch_version,
    repo_version  => $repo_version,
    #autoupgrade   => true,
    #package_url   => "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${es_version}.deb",
    config        => {
      'cluster.name'                         => $cluster_name,
      'discovery.zen.ping.multicast.enabled' => false,
# es is unreachable with following option, because it is bound to 10.0.2.14 on vagrant (why?)
#      'network.host' => '127.0.0.1',
    },
    init_defaults => {
      'ES_HEAP_SIZE' => $es_heap_size,
    },
    java_install  => false,
  }

  elasticsearch::instance { 'masternode':
    config => {
      'node.master'                      => true,
      'node.data'                        => true,
      'http.port'                        => $dhrep::params::tgelasticsearch_master_http_port,
      'transport.tcp.port'               => $dhrep::params::tgelasticsearch_master_tcp_port,
      'discovery.zen.ping.unicast.hosts' => "127.0.0.1:${dhrep::params::tgelasticsearch_workhorse_tcp_port}",
    }
  }

  elasticsearch::instance { 'workhorse':
    config => {
      'node.master'                      => false,
      'node.data'                        => true,
      'http.port'                        => $dhrep::params::tgelasticsearch_workhorse_http_port,
      'transport.tcp.port'               => $dhrep::params::tgelasticsearch_workhorse_tcp_port,
      'discovery.zen.ping.unicast.hosts' => "127.0.0.1:${dhrep::params::tgelasticsearch_master_tcp_port}",
    }
  }

  elasticsearch::plugin{"elasticsearch/elasticsearch-mapper-attachments/${attachments_plugin_version}":
    instances  => ['masternode', 'workhorse'],
  }

  elasticsearch::plugin{"org.wikimedia.search.highlighter/experimental-highlighter-elasticsearch-plugin/${highlighter_plugin_version}":
    instances  => ['masternode', 'workhorse'],
  }

  # run only once
  unless $::tgelastic_repos_initialized {
    # clone commons repo, which contains shell scripts to create textgrid elastic search indizes
    exec { 'git_clone_tgcommon':
      path    => ['/usr/bin','/bin','/usr/sbin'],
      command => 'git clone git://git.projects.gwdg.de/common.git /usr/local/src/tgcommon-git',
      creates => '/usr/local/src/tgcommon-git',
      require => Package['git'],
    }
    ->
    dhrep::tools::wait_for_url_ready { 'wait_for_es_master':
      url     => "http://localhost:${dhrep::params::tgelasticsearch_master_http_port}/",
      require => Elasticsearch::Instance['masternode'],
    }
    ~>
    exec { 'create_public_es_index':
      path    => ['/usr/bin','/bin','/usr/sbin'],
      cwd     => '/usr/local/src/tgcommon-git/esutils/tools/createIndex/',
      command => "/usr/local/src/tgcommon-git/esutils/tools/createIndex/createAllPublic.sh localhost:${dhrep::params::tgelasticsearch_master_http_port}",
      require => [Package['curl']],
    }
    ~>
    exec { 'create_nonpublic_es_index':
      path    => ['/usr/bin','/bin','/usr/sbin'],
      cwd     => '/usr/local/src/tgcommon-git/esutils/tools/createIndex/',
      command => "/usr/local/src/tgcommon-git/esutils/tools/createIndex/createAllNonpublic.sh localhost:${dhrep::params::tgelasticsearch_master_http_port}",
      require => [Package['curl']],
    }
    ~>
    file { '/etc/facter/facts.d/tgelastic_repos_initialized.txt':
      content => 'tgelastic_repos_initialized=true',
    }
  }

  ###
  # collectd for elasticsearch
  ###

  # install the collectd plugin for elasticsearch
  vcsrepo { '/opt/collectd-elasticsearch':
    ensure   => present,
    owner    => 'root',
    group    => 'root',
    provider => git,
    source   => 'https://github.com/phobos182/collectd-elasticsearch.git',
  }

  @file { '/etc/collectd/conf.d/88-elastic.conf':
    tag     => 'femonitoring_collectd',
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    content => "<LoadPlugin \"python\">
    Globals true
</LoadPlugin>

<Plugin \"python\">
    ModulePath \"/opt/collectd-elasticsearch/\"

    Import \"elasticsearch\"

    <Module \"elasticsearch\">
        Verbose false
        Version \"1.0\"
        Cluster \"elasticsearch\"
    </Module>
</Plugin>
",
  }

  ###
  # nrpe
  ###

  # do python setup:
  #   package python-pip
  #   pip install nagios-plugin-elasticsearch
  exec { 'nagios-plugin-elasticsearch':
    command => '/usr/bin/pip install nagios-plugin-elasticsearch',
    require => Package['python-pip'],
  }
  ->
  dariahcommon::nagios_service { 'check_elasticsearch':
    command => "check_elasticsearch -p 9202 -vv",
  }

}
