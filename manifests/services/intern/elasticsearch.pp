# == Class: dhrep::services::intern::elasticsearch
#
# === Description
#
# Class to install and configure elasticsearch for dhrep services, scope: textgrid and dariah.
#
# === Notes
#
# Initial database creation is now done by the script /opt/dhrep/init_databases.sh!
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
class dhrep::services::intern::elasticsearch (
  $scope                      = undef,
  $cluster_name               = undef,
  $repo_version               = 6,
  $elasticsearch_version      = '6.5.4',
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
  class { 'elastic_stack::repo':
    version => $repo_version,
    oss     => true,
  }

  apt::pin { 'elasticsearch':
    packages => 'elasticsearch-oss',
    version  => $elasticsearch_version,
    priority => 1000,
  }

  class { '::elasticsearch':
    version           => $elasticsearch_version,
    autoupgrade       => false,
    restart_on_change => true,
    oss               => true,
    jvm_options       => [ "-Xms${_es_heap_size}", "-Xmx${_es_heap_size} -Dlog4j2.formatMsgNoLookups=true" ],
    config            => {
      'cluster.name'    => $cluster_name,
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

  # clone commons repo, which contains shell scripts to create textgrid elastic search indexes
  # FIXME use vcsrepo!
  exec { 'git_clone_tgcommon':
    path    => ['/usr/bin','/bin','/usr/sbin'],
    command => 'git clone https://gitlab.gwdg.de/dariah-de/dariah-de-common.git /usr/local/src/tgcommon-git',
    creates => '/usr/local/src/tgcommon-git',
    require => Package['git'],
  }

  ###
  # telegraf for elasticsearch
  ###
  telegraf::input { 'elasticsearch_workhorse':
    plugin_type => 'elasticsearch',
    options     => [{
        'servers'        => ["http://localhost:${_master_http_port}", "http://localhost:${_workhorse_http_port}"],
        'http_timeout'   => '5s',
        'local'          => true,
        'cluster_health' => false,
        'cluster_stats'  => false,
    }],
  }

  ###
  # nrpe
  ###
  package { 'python-setuptools':
    ensure => installed,
  }

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
