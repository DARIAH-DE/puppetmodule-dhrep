class textgrid::tools {

  file { "/usr/local/bin/wait_for_url_ready.sh":
    mode    => '0744',
    source  => 'puppet:///modules/textgrid/tools/wait_for_url_ready.sh',
  }

}