define textgrid::tools::tgstaging(
  $source,
  $target,
  $creates = undef,
){
  $tgcache = '/var/cache/textgrid/'
 
  # vagrant cachier changes this to symlink TODO: workaround
  file { $tgcache:
    ensure => directory,
  }

  staging::file { $name:
    source  => $source,
    target  => "${tgcache}/${name}",
  }
  ->
  staging::extract { $name:
    source  => "${tgcache}/${name}",
    target  => $target,
    creates => $creates,
  }

}
