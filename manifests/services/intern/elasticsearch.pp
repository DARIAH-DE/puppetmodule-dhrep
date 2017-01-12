# == Class: dhrep::services::intern::elasticsearch
#
# Class to install and configure elasticsearch.
#
# === Parameters
#
# [*scope*]
#   textgrid or dariah
#
# [*cluster_name*]
#   name of elastic search cluster
#
# [*repo_version*]
#   version of elasticsearch repo
#
# [*elasticsearch_version*]
#   version of elasticsearch
#
# [*attachment_plugin_version*]
#   version of elasticsearch attachment plugin
#
# [*highlighter_plugin_version*]
#   version of elasticsearch highlighter plugin
#
class dhrep::services::intern::elasticsearch (
  $scope                      = undef,
  $cluster_name               = undef,
  $repo_version               = '1.7',
  $elasticsearch_version      = '1.7.5',
  $attachments_plugin_version = '2.7.0',
  $highlighter_plugin_version = '1.7.0',
) inherits dhrep::params {

  $_master_http_port    = $::dhrep::params::elasticsearch_master_http_port
  $_master_tcp_port     = $::dhrep::params::elasticsearch_master_tcp_port
  $_workhorse_http_port = $::dhrep::params::elasticsearch_workhorse_http_port
  $_workhorse_tcp_port  = $::dhrep::params::elasticsearch_workhorse_tcp_port
  $_es_heap_size        = $::dhrep::params::elasticsearch_es_heap_size

  package {
    'python-pip': ensure => present,
  }

  # read docs at https://github.com/elasticsearch/puppet-elasticsearch/tree/master
  class { '::elasticsearch':
    manage_repo   => true,
    version       => $elasticsearch_version,
    repo_version  => $repo_version,
    #autoupgrade   => true,
    #package_url   => "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${version}.deb",
    config        => {
      'cluster.name'                         => $cluster_name,
      'discovery.zen.ping.multicast.enabled' => false,
# es is unreachable with following option, because it is bound to 10.0.2.14 on vagrant (why?)
#      'network.host' => '127.0.0.1',
    },
    init_defaults => {
      'ES_HEAP_SIZE' => $_es_heap_size,
    },
    java_install  => false,
  }

  ::elasticsearch::instance { 'masternode':
    config => {
      'node.master'                      => true,
      'node.data'                        => true,
      'http.port'                        => $_master_http_port,
      'transport.tcp.port'               => $_master_tcp_port,
      'discovery.zen.ping.unicast.hosts' => "127.0.0.1:${_workhorse_tcp_port}",
    }
  }

  ::elasticsearch::instance { 'workhorse':
    config => {
      'node.master'                      => false,
      'node.data'                        => true,
      'http.port'                        => $_workhorse_http_port,
      'transport.tcp.port'               => $_workhorse_tcp_port,
      'discovery.zen.ping.unicast.hosts' => "127.0.0.1:${_master_tcp_port}",
    }
  }

  ::elasticsearch::plugin{"elasticsearch/elasticsearch-mapper-attachments/${attachments_plugin_version}":
    instances  => ['masternode', 'workhorse'],
  }

  ::elasticsearch::plugin{"org.wikimedia.search.highlighter/experimental-highlighter-elasticsearch-plugin/${highlighter_plugin_version}":
    instances  => ['masternode', 'workhorse'],
  }

  # run only once
#  unless ($::elastic_repos_initialized) {
    # clone commons repo, which contains shell scripts to create textgrid elastic search indexes
    # FIXME use vcsrepo!
    exec { 'git_clone_tgcommon':
      path    => ['/usr/bin','/bin','/usr/sbin'],
      command => 'git clone git://git.projects.gwdg.de/common.git /usr/local/src/tgcommon-git',
      creates => '/usr/local/src/tgcommon-git',
      require => Package['git'],
    }
#    ->
#    dhrep::tools::wait_for_url_ready { 'wait_for_es_master':
#      url     => "http://localhost:${_master_http_port}/",
#      require => Elasticsearch::Instance['masternode'],
#    }
#    ~>
# TODO if creating a new dhrep server instance, please manually create es index first before using!!
#    exec { 'create_public_es_index':
#      path    => ['/usr/bin','/bin','/usr/sbin'],
#      cwd     => '/usr/local/src/tgcommon-git/esutils/tools/createIndex/',
#      command => "/usr/local/src/tgcommon-git/esutils/tools/createIndex/createAllPublic.sh localhost:${_master_http_port}",
#      require => [Package['curl']],
#    }
#    ~>
#    exec { 'create_nonpublic_es_index':
#      path    => ['/usr/bin','/bin','/usr/sbin'],
#      cwd     => '/usr/local/src/tgcommon-git/esutils/tools/createIndex/',
#      command => "/usr/local/src/tgcommon-git/esutils/tools/createIndex/createAllNonpublic.sh localhost:${_master_http_port}",
#      require => [Package['curl']],
#    }
#    ~>
#    file { '/etc/facter/facts.d/elastic_repos_initialized.txt':
#      content => 'elastic_repos_initialized=true',
#    }
#  }

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
    tag     => 'gwdgmetrics_collectd',
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
        Cluster \"${cluster_name}\"
        Port ${_master_http_port}
    </Module>
</Plugin>
",
  }

  # TODO, move to fe-monitoring
  #package { 'libyajl2': }

  collectd::plugin::curl_json { 'elasticsearch_workhorse':
    url => "http://localhost:${_workhorse_http_port}/_nodes/${::hostname}-workhorse/stats/jvm/",
    instance => 'elasticsearch_workhorse',
    keys => {
      'nodes/*/jvm/mem/heap_max_in_bytes'  => {'type' => 'bytes'},
      'nodes/*/jvm/mem/heap_used_in_bytes' => {'type' => 'bytes'},
    }
  }

  ###
  # nrpe
  ###
  package{ "python-setuptools" : ensure => installed }
  package { "nagios-plugin-elasticsearch":
      # ensure latest does not work right now, compare https://bugs.launchpad.net/ubuntu/+source/dbus/+bug/1593749
      # possibly with puppet 4? do we need 'latest' at all?
      # ensure  => latest,
      ensure => '1.1.0',
      provider => pip,
      require => Package['python-setuptools'],
  }
  ->
  dariahcommon::nagios_service { 'check_elasticsearch':
    command => "check_elasticsearch -p ${$_master_http_port} -vv",
  }
}
