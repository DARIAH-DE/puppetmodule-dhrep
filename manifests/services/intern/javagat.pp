# == Class: textgrid::services::intern::javagat
#
# Class to install and configure JavaGAT.
#
class textgrid::services::intern::javagat (
  $javagat_version = '2.1.1',
){

  include textgrid::services::intern::datadirs

  ###
  # javagat
  ###

  textgrid::tools::tgstaging { "JavaGAT-${javagat_version}-binary.zip":
    source  => "http://gforge.cs.vu.nl/gf/download/frsrelease/154/1196/JavaGAT-${javagat_version}-binary.zip",
    target  => '/usr/local',
    creates => "/usr/local/JavaGAT-${javagat_version}",
  }

  file { '/usr/local/javagat':
    ensure => link,
    target => "/usr/local/JavaGAT-${javagat_version}",
  }

}
