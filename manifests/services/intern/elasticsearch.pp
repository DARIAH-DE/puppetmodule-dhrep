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
#  $repo_version               = 5,
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

  ###
  # elasticsearch
  ###
  # PLEASE NOTE read docs at <https://github.com/elasticsearch/puppet-elasticsearch/tree/master>
  # PLEASE NOTE for upgrading from 1.x to 5.x, please see <https://www.elastic.co/guide/en/elasticsearch/reference/5.6/setup-upgrade.html>
  #class { 'elastic_stack::repo':
  #  version => $repo_version,
  #}

  # for using es 1.7 with newer es-puppet module, remove code below and use elastic_stack::repo for es update
  apt::source { 'elasticsearch':
    comment  => '',
    location => 'http://packages.elastic.co/elasticsearch/1.7/debian',
    release  => 'stable',
    repos    => 'main',
    key      => {
      'server' => 'keys.gnupg.net',
      'id'     => '46095ACC8548582C1A2699A9D27D666CD88E42B4',
    },
    include  => {
      'src' => false,
      'deb' => true,
    },
  }

  class { '::elasticsearch':
    manage_repo   => false,
    version       => $elasticsearch_version,
    autoupgrade   => false,
    config        => {
      'cluster.name'                         => $cluster_name,
      'discovery.zen.ping.multicast.enabled' => false,
      # Elasticsearch is unreachable with following option, because it is bound to 10.0.2.14 on vagrant (why?)
      # 'network.host' => '127.0.0.1',
    },
    jvm_options => [ "-Xms${_es_heap_size}", "-Xmx${_es_heap_size}" ],
    # backwards compatibility to old elasticsearch puppet module
    # TODO: remove this option if rebuilding server
    datadir => '/usr/share/elasticsearch/data',
    init_defaults => {
      'DATA_DIR' => '$ES_HOME/data',
    },
  }

  ::elasticsearch::instance { 'masternode':
    config  => {
      'node.master'                      => true,
      'node.data'                        => true,
      'http.port'                        => $_master_http_port,
      'transport.tcp.port'               => $_master_tcp_port,
      'discovery.zen.ping.unicast.hosts' => "127.0.0.1:${_workhorse_tcp_port}",
    },
  }

  ::elasticsearch::instance { 'workhorse':
    config  => {
      'node.master'                      => false,
      'node.data'                        => true,
      'http.port'                        => $_workhorse_http_port,
      'transport.tcp.port'               => $_workhorse_tcp_port,
      'discovery.zen.ping.unicast.hosts' => "127.0.0.1:${_master_tcp_port}",
    },
  }

# PLEASE NOTE commented out due to es upgrade to version 5.6, please check versions ans comment in again then!
#  ::elasticsearch::plugin{"elasticsearch/elasticsearch-mapper-attachments/${attachments_plugin_version}":
#    instances  => ['masternode', 'workhorse'],
#  }
#  ::elasticsearch::plugin{"org.wikimedia.search.highlighter/experimental-highlighter-elasticsearch-plugin/${highlighter_plugin_version}":
#    instances  => ['masternode', 'workhorse'],
#    module_dir => 'experimental-highlighter-elasticsearch-plugin',
#  }

  # run only once
  #  unless ($::elastic_repos_initialized) {
  # clone commons repo, which contains shell scripts to create textgrid elastic search indexes
  # FIXME use vcsrepo!
  exec { 'git_clone_tgcommon':
    path    => ['/usr/bin','/bin','/usr/sbin'],
    command => 'git clone git://projects.gwdg.de/dariah-de/tg/textgrid-repository/common.git /usr/local/src/tgcommon-git',
    creates => '/usr/local/src/tgcommon-git',
    require => Package['git'],
  }

  ###
  # PLEASE NOTE database creation is now done by /opt/dhrep/init_databases.sh!
  ###

  ###
  # telegraf for elasticsearch
  ###
  telegraf::input { 'elasticsearch_workhorse':
    plugin_type => 'elasticsearch',
    options     => {
      'servers'        => ["http://localhost:${_master_http_port}", "http://localhost:${_workhorse_http_port}"],
      'http_timeout'   => '5s',
      'local'          => true,
      'cluster_health' => false,
      'cluster_stats'  => false,
    },
  }

  ###
  # nrpe
  ###
  package{ 'python-setuptools' : ensure => installed }
  package { 'nagios-plugin-elasticsearch':
    # ensure latest does not work right now, compare https://bugs.launchpad.net/ubuntu/+source/dbus/+bug/1593749
    # possibly with puppet 4? do we need 'latest' at all?
    # ensure  => latest,
    ensure   => '1.1.0',
    provider => pip,
    require  => Package['python-setuptools'],
  }
  -> nrpe::plugin { 'check_elasticsearch':
    plugin     => 'check_elasticsearch',
    libexecdir => '/usr/local/bin',
    args       => "-p ${$_master_http_port} -vv",
  }
}
