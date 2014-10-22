class textgrid::services::intern::messaging {

  exec { 'git_clone_messagebeans':
    command => 'git clone git://git.projects.gwdg.de/textgrid-messagebeans.git /usr/local/src/messagebeans-git',
    path => ['/usr/bin','/bin','/usr/sbin'],
    creates => '/usr/local/src/messagebeans-git',
    require => Package['git'],
  }

}
