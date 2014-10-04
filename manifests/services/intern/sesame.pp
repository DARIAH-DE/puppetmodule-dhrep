class textgrid::services::intern::sesame {

  $tgname = 'tomcat-sesame'
  $http_port = '9091'
  $control_port = '9006'
  $jmx_port = '9991'

  # http://sourceforge.net/projects/sesame/files/Sesame%202/2.7.13/openrdf-sesame-2.7.13-sdk.tar.gz/download
  #$sesame_version = '2.7.13'
  $sesame_version = '2.7.8'
  $sesame_file = "openrdf-sesame-${sesame_version}-sdk.tar.gz"

  textgrid::resources::servicetomcat { $tgname:
    gid          => '1008',
    uid          => '1008',
    http_port    => $http_port,
    control_port => $control_port,
    jmx_port     => $jmx_port,
  }

  staging::deploy { $sesame_file:
    source => "http://sourceforge.net/projects/sesame/files/Sesame%202/${sesame_version}/${sesame_file}/download",
    target => "/home/${tgname}",
    notify => [Tomcat::War['openrdf-workbench.war'], Tomcat::War['openrdf-sesame.war']],
  }

  tomcat::war { 'openrdf-workbench.war':
    war_ensure    => present,
    catalina_base => "/home/${tgname}/${tgname}",
    war_source    => "/home/${tgname}/openrdf-sesame-${sesame_version}/war/openrdf-workbench.war",
    require       => [Textgrid::Resources::Servicetomcat[$tgname], Staging::Deploy[$sesame_file]],
  }

  tomcat::war { 'openrdf-sesame.war':
    war_ensure    => present,
    catalina_base => "/home/${tgname}/${tgname}",
    war_source    => "/home/${tgname}/openrdf-sesame-${sesame_version}/war/openrdf-sesame.war",
    require       => [Textgrid::Resources::Servicetomcat[$tgname], Staging::Deploy[$sesame_file]],
  }

#    file { "/home/${tgname}/repo1.trig":
#        ensure  => present,
#        owner   => $tgname,
#        group   => $tgname,
#        mode    => '644',
#        source  => "puppet:///modules/textgrid/rdf/repo1.trig",
#    }

#	exec { 'create_sesame_repos':
#		path    => ['/usr/bin','/bin','/usr/sbin'],
#		command => "curl -X POST -d @/home/tomcat-sesame/repo1.trig http://localhost:9091/openrdf-sesame/repositories/SYSTEM/statements --header 'Content-Type: application/x-trig;charset=UTF-8'",
#		require => File["/home/${tgname}/repo1.trig"],
#	}

#	exec { 'create_sesame_public_repo':
#		path    => ['/usr/bin','/bin','/usr/sbin'],
#		command => "curl 'http://localhost:9091/openrdf-workbench/repositories/SYSTEM/create' --data 'type=native&Repository+ID=textgrid-public&Repository+title=rdf+repo+for+public+textgrid+data&Triple+indexes=spoc%2Cposc%2Copsc%2Csopc'",
#	}

#	exec { 'mime_to_sesame_public_repo':
#		path    => ['/usr/bin','/bin','/usr/sbin'],
#		command => "curl 'http://localhost:9091/openrdf-sesame/repositories/textgrid-public/statements' -X POST -d @/home/tomcat-sesame/mime.ttl --header 'Content-Type: text/turtle;charset=UTF-8'",
#		require => [Exec['create_sesame_public_repo'],File["/home/${tgname}/mime.ttl"]],
#	}

#	exec { 'create_sesame_nonpublic_repo':
#		path    => ['/usr/bin','/bin','/usr/sbin'],
#		command => "curl 'http://localhost:9091/openrdf-workbench/repositories/SYSTEM/create' --data 'type=native&Repository+ID=textgrid-nonpublic&Repository+title=rdf+repo+for+nonpublic+textgrid+data&Triple+indexes=spoc%2Cposc%2Copsc%2Csopc'",
#	}

#	exec { 'mime_to_sesame_nonpublic_repo':
#		path    => ['/usr/bin','/bin','/usr/sbin'],
#		command => "curl 'http://localhost:9091/openrdf-sesame/repositories/textgrid-nonpublic/statements' -X POST -d @/home/tomcat-sesame/mime.ttl --header 'Content-Type: text/turtle;charset=UTF-8'",
#		require => [Exec['create_sesame_nonpublic_repo'],File["/home/${tgname}/mime.ttl"]],
#	}

  file { "/home/${tgname}/mime.ttl":
    ensure => present,
    owner  => $tgname,
    group  => $tgname,
    mode   => '0644',
    source => 'puppet:///modules/textgrid/rdf/mime.ttl',
  }

  define create_tgrepo (
    $port = '9091',
    $user = 'tomcat-sesame'
  ) {

    $create_target = shellquote("http://localhost:${port}/openrdf-workbench/repositories/SYSTEM/create")
    $create_data = shellquote("type=native&Repository+ID=${name}&Repository+title=rdf+repo+for+${name}+data&Triple+indexes=spoc%2Cposc%2Copsc%2Csopc")

    exec { "create_repo_${name}":
      path    => ['/usr/bin','/bin','/usr/sbin'],
      command => "curl ${create_target} --data ${create_data}",
    }

    $ttl_target = shellquote("http://localhost:${port}/openrdf-sesame/repositories/${name}/statements")

    exec { "ttl_to_repo_${name}":
      path    => ['/usr/bin','/bin','/usr/sbin'],
      command => "curl ${ttl_target} -X POST -d @/home/tomcat-sesame/mime.ttl --header 'Content-Type: text/turtle;charset=UTF-8'",
      require => [Exec["create_repo_${name}"],File["/home/${user}/mime.ttl"]],
    }

  }

  create_tgrepo{'textgrid-nonpublic':
    port => '9091',
    user => $tgname,
#    creates => "/home/$tgname/.aduna/openrdf-sesame/repositories/textgrid-nonpublic",
  }

  create_tgrepo{'textgrid-public':
    port => '9091',
    user => $tgname,
  }

  # add tg repos
  # todo: how to test for already done
  # todo: better readable command exec
  #	exec {'create_public_sesame_repos':
  #		path    => ['/usr/bin','/bin','/usr/sbin'],
  #		command => "echo -e 'connect http://localhost:9091/openrdf-sesame.\ncreate native.\ntextgrid-public\nrdf repo for public textgrid data\nspoc,posc,opsc,sopc\nopen textgrid-public.\nload /home/${tgname}/mime.ttl.\nexit.' | /home/${tgname}/openrdf-sesame-${sesame_version}/bin/console.sh",	
  #        creates => "/home/${tgname}/.aduna/",
  #		require => [Staging::Deploy[$sesame_file], File["/home/${tgname}/mime.ttl"]],
  #	}

}
