# == Class: cspace_source
#
# Full description of class cspace_source here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { cspace_source:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2013 Your name here, unless otherwise noted.
#

# May require installation of the puppetlabs/vcsrepo module; e.g.
# sudo puppet module install puppetlabs-vcsrepo

# Test standlone with a reference to the modulepath in which that module is installed; e.g.
# puppet apply --modulepath=/etc/puppet/modules ./manifests/init.pp

class cspace_source {
	
	file { 'Create CollectionSpace source directory':
	    path   => "/tmp/cspace-source",
	    ensure => "directory",
	}
    
	vcsrepo { '/tmp/cspace-source/application':
	    require => File['Create CollectionSpace source directory'],
        # require  => [ Package["git"] ],
	    provider => 'git',
        source   => 'https://github.com/collectionspace/application.git',
        revision => 'master',
    }

	vcsrepo { '/tmp/cspace-source/services':
        require => File['Create CollectionSpace source directory'],
        # require  => [ Package["git"] ],
	    provider => 'git',
        source   => 'https://github.com/collectionspace/services.git',
        revision => 'master',
    }

	vcsrepo { '/tmp/cspace-source/ui':
        require => File['Create CollectionSpace source directory'],
        # require  => [ Package["git"] ],
	    provider => 'git',
        source   => 'https://github.com/collectionspace/ui.git',
        revision => 'master',
    }
	
	# For testing
	exec { 'Maven clean of Application layer source':
        require => Vcsrepo['/tmp/cspace-source/application'],
	    command => 'mvn clean',
	    cwd => '/tmp/cspace-source/application',
	    path => ['/bin', '/usr/bin'],
	}
}

include cspace_source
