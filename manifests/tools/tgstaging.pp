define dhrep::tools::tgstaging(
  $source,
  $target,
  $creates = undef,
){

  $tgcache = '/var/cache/textgrid/'

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
