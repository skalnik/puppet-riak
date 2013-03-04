# Installs custom Riak from homebrew. Auto-requires riak::config.
#
# Usage:
#
#     include riak
class riak {
  include riak::config
  include homebrew

  file { [
    $riak::config::configdir,
    $riak::config::datadir,
    $riak::config::logdir
  ]:
    ensure => directory
  }

  file { "${riak::config::configdir}/app.config":
    content => template('riak/app.config.erb'),
  #    notify  => Service['dev.riak']
  }

  file { '/Library/LaunchDaemons/dev.riak.plist':
    content => template('riak/dev.riak.plist.erb'),
    group   => 'wheel',
    owner   => 'root',
  #    notify  => Service['dev.riak']
  }

  file { '/etc/launchd.conf':
    content => 'limit maxfiles 2048 unlimited',
    group   => 'wheel',
    owner   => 'root',
    ensure  => 'present'
  }

  homebrew::formula { 'riak':
    before => Package['boxen/brews/riak']
  }

  package { 'boxen/brews/riak':
    ensure => $riak::config::version,
    notify => Service['dev.riak']
  }

  service { 'dev.riak':
    ensure  => 'stopped',
    require => Package['boxen/brews/riak']
  }

  service { 'com.boxen.riak': # replaced by dev.riak
    before => Service['dev.riak'],
    enable => false
  }

  file { "${boxen::config::envdir}/riak.sh":
    content => template('riak/env.sh.erb'),
    require => File[$boxen::config::envdir]
  }

  file { "${boxen::config::homebrewdir}/Cellar/riak/${riak::config::version}/libexec/etc/app.config":
    ensure  => link,
    force   => true,
    target  => "${riak::config::configdir}/app.config",
    require => [Package['boxen/brews/riak'],
      File["${riak::config::configdir}/app.config"]]
  }
}
