# Class baselayout
#
#  Provides the baselayout configuration.
#
# @author Gunnar Wrobel <p@rdus.de>
# @version 1.0
# @package baselayout
#
class baselayout (
  $timezone = "UTC",
) {
  
  include concat::setup

  # Package installation
  case $::operatingsystem {
    gentoo:
    {
#       gentoo_keywords { 'baselayout':
#         context  => 'tool_baselayout_baselayout',
#         package  => '=sys-apps/baselayout-2.0.1',
#         keywords => "~$keyword",
#         tag      => 'buildhost'
#       }
#       gentoo_keywords { 'openrc':
#         context  => 'tool_baselayout_openrc',
#         package  => '=sys-apps/openrc-0.6.3',
#         keywords => "~$keyword",
#         tag      => 'buildhost'
#       }
      package { 
        'udev':
          category => 'sys-fs',
          ensure   => 'latest',
          tag      => 'buildhost';
        
        'baselayout':
          category => 'sys-apps',
          ensure   => 'latest',
          tag      => 'buildhost';
          
        'openrc':
          category => 'sys-apps',
          ensure   => 'latest',
          require  => [Package['udev'], Package['baselayout']],
          tag      => 'buildhost';
          
        'sysvinit':
          category => 'sys-apps',
          ensure   => 'installed',
          tag      => 'buildhost';
      }
    }
  }

  concat { '/etc/fstab':
  }
   
  concat::fragment{'fstab_header':
    target  => '/etc/fstab',
    content => template('baselayout/fstab'),
    order   => 01,
  }
  
  file { '/etc/conf.d/hostname':
    content => template("baselayout/hostname"),
    require => Package['openrc'],
  }

  file { '/etc/timezone':
    content => $timezone,
    require => Package['baselayout']
  }
  
  file { '/etc/localtime':
    ensure => 'link',
    target => "/usr/share/zoneinfo/$timezone",
  }

  case $::operatingsystem {
    gentoo: {
      baselayout::runlevel_service {
        ['bootmisc', 'hostname', 'mtab', 'net.lo']:
          runlevel => 'boot',
      }
      baselayout::runlevel_service { 'local':
          runlevel => 'default',
      }
      case $::virtual {
        'physical', 'xenu':
        {
          baselayout::runlevel_service {
            [
              'consolefont', 'fsck', 'hdparm', 'hwclock', 'keymaps',
              'localmount', 'modules', 'procfs', 'root', 'swap', 'sysctl',
              'termencoding', 'urandom'
            ]:
              runlevel => 'boot',
          }
          case $::virtual {
            'physical':
            {
              baselayout::runlevel_service { 'numlock':
                runlevel => 'boot',
              }
            }
          }
        }
        'openvz':
        {
          baselayout::runlevel_service {
            [
              'consolefont', 'fsck', 'hdparm', 'hwclock', 'keymaps',
              'localmount', 'modules', 'procfs', 'root', 'swap', 'sysctl',
              'termencoding', 'urandom', 'numlock'
            ]:
              runlevel => 'boot',
              ensure   => 'absent',
          }
          baselayout::net_iface { 'venet0':
          }
          baselayout::runlevel_service { 'net.venet0':
          }
        }
      }
    }
  }
}

define baselayout::mount(
  $device,
  $mountpoint = $title,
  $type = 'auto',
  $options = [],
  $dump = 0,
  $pass = 0
) {
  if $options == [] {
    $options_str = 'defaults'
  } else {
    $options_str = join($options, ",")
  }
  
  concat::fragment { "fstab_fragment_$title":
    target  => '/etc/fstab',
    content => "$device\t\t$mountpoint\t\t$type\t$options_str\t$dump $pass\n"
  }
}

define baselayout::runlevel_service(
  $service = $title,
  $runlevel = 'default',
  $ensure = 'present',
) {
  case $ensure {
    'present': {
      $file_ensure = 'link'
    }
    'absent': {
      $file_ensure = 'absent'
    }
  }
  file { "/etc/runlevels/$runlevel/$service":
    target  => "/etc/init.d/$service",
    ensure  => $file_ensure,
    require => Package['openrc'],
  }
}


define baselayout::net_iface(
  $iface = $title,
  $ensure = 'present',
) {
  case $ensure {
    'present': {
      $file_ensure = 'link'
    }
    'absent': {
      $file_ensure = 'absent'
    }
  }
  file { "/etc/init.d/net.$iface":
    target  => '/etc/init.d/net.lo',
    ensure  => $file_ensure,
    require => Package['openrc'],
  }
}