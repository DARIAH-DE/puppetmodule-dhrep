# == Class: textgrid::services::intern::sesame
#
# Class to install and configure sesame.
# Creates initial repos textgrid-nonpublic 
# and textgrid-public and adds initial triples.
#
class textgrid::services::intern::sesame {

  $tgname = 'tomcat-sesame'
  $http_port = '9091'
  $control_port = '9006'
  $jmx_port = '9991'

  $sesame_version = '2.7.13'
  $sesame_file = "openrdf-sesame-${sesame_version}-sdk.tar.gz"

  #require textgrid::resources::create_rdf_repository

  textgrid::resources::servicetomcat { $tgname:
    gid          => '1008',
    uid          => '1008',
    http_port    => $http_port,
    control_port => $control_port,
    jmx_port     => $jmx_port,
  }

  textgrid::tools::tgstaging { $sesame_file:
    source  => "http://sourceforge.net/projects/sesame/files/Sesame%202/${sesame_version}/${sesame_file}/download",
    target  => "/home/${tgname}",
    creates => "/home/${tgname}/openrdf-sesame-${sesame_version}",
  }

#  $tgcache = '/var/cache/textgrid/'
#  file { $tgcache:
#    ensure => directory,
#  }

#  staging::file { $sesame_file:
#    source  => "http://sourceforge.net/projects/sesame/files/Sesame%202/${sesame_version}/${sesame_file}/download",
#    target  => "${tgcache}/${sesame_file}",
#  }
#  ->
#  staging::extract { $sesame_file:
#    source  => "${tgcache}/${sesame_file}",
#    target  => "/home/${tgname}",
#    creates => "/home/${tgname}/openrdf-sesame-${sesame_version}",
#  }
  ~>
  tomcat::war { 'openrdf-workbench.war':
    war_ensure    => present,
    catalina_base => "/home/${tgname}/${tgname}",
    war_source    => "/home/${tgname}/openrdf-sesame-${sesame_version}/war/openrdf-workbench.war",
    require       => [Textgrid::Resources::Servicetomcat[$tgname]],
  }
  ~>
  tomcat::war { 'openrdf-sesame.war':
    war_ensure    => present,
    catalina_base => "/home/${tgname}/${tgname}",
    war_source    => "/home/${tgname}/openrdf-sesame-${sesame_version}/war/openrdf-sesame.war",
    require       => [Textgrid::Resources::Servicetomcat[$tgname],Tomcat::War['openrdf-workbench.war']],
  }

  file { "/home/${tgname}/mime.ttl":
    ensure  => present,
    owner   => $user,
    mode    => '0644',
    source  => 'puppet:///modules/textgrid/rdf/mime.ttl',
    require => User[$tgname]
  }

  unless $sesame_nonpublic_repo_created {
    textgrid::resources::create_rdf_repository{'textgrid-nonpublic':
      port    => '9091',
      user    => $tgname,
    }
    ->
    file {'/etc/facter/facts.d/sesame_nonpublic.txt':
      content => 'sesame_nonpublic_repo_created=true',
    }
  }

  unless $sesame_public_repo_created {
    textgrid::resources::create_rdf_repository{'textgrid-public':
      port    => '9091',
      user    => $tgname,
    }
    ->
    file {'/etc/facter/facts.d/sesame_public.txt':
      content => 'sesame_public_repo_created=true',
    }
  }



}
