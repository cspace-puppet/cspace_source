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
# puppet apply --modulepath=/etc/puppet/modules ./tests/init.pp

class cspace_source( $env_vars, $exec_paths = [ '/bin', '/usr/bin' ] ) {
	
	# ---------------------------------------------------------
	# Verify environment variables (uncomment for debugging)
	# ---------------------------------------------------------
	    
    # Note that the 'user' property is currently commented out.
    # If we set that property, it appears that the 'exec':
    #
    # a) must be run as root; and
    # b) is then given root's environment, not that of the designated user.
    # (That may not always be what we intend.)
    #
    # When the 'user' property is set and this 'exec' is then run as
    # a non-root user, the following error occurs:
    # "Error: Parameter user failed on Exec[...]:
    # Only root can execute commands as other users""
    
    # exec { 'Check values of environment variables':
    #     command   => 'env',
    #     path      => $exec_paths,
    #     logoutput => 'true',
    #     environment => [ $env_vars ]
    #     # user      => 'cspace',
    # }
	
	# ---------------------------------------------------------
	# Verify presence of required resources
	# ---------------------------------------------------------
	
    exec { 'Find Ant executable':
	    command   => '/bin/sh -c "command -v ant"',
	    path      => $exec_paths,
        logoutput => 'true',
	}

    exec { 'Find Git executable':
	    command   => '/bin/sh -c "command -v git"',
	    path      => $exec_paths,
        logoutput => 'true',
	}
	
    exec { 'Find Maven executable':
	    command   => '/bin/sh -c "command -v mvn"',
	    path      => $exec_paths,
        logoutput => 'true',
	}
	
	# FIXME: This should use a more flexible mechanism for
	# identifying the directory which should contain the
	# CollectionSpace source code.
	#
	# FIXME: This should default to a system-specific temporary
	# directory, not to '/tmp'.
    file { 'Ensure CollectionSpace source directory':
        ensure => 'directory',
        path   => '/tmp/cspace-source',
        require => [
		    Exec[ 'Find Ant executable' ],
		    Exec[ 'Find Git executable' ],
		    Exec[ 'Find Maven executable' ],
		],
    }
	
	# ---------------------------------------------------------
	# Download CollectionSpace source code
	# ---------------------------------------------------------
	
    # Download the Application layer source code
    
    vcsrepo { 'Download Application layer source code':
        ensure   => latest,
        provider => 'git',
        source   => 'https://github.com/collectionspace/application.git',
        revision => 'master',
	    path     => '/tmp/cspace-source/application',
        require  => File[ 'Ensure CollectionSpace source directory' ],
    }

    # Download the Services layer source code
    
    vcsrepo { 'Download Services layer source code':
        ensure   => latest,
        provider => 'git',
        source   => 'https://github.com/collectionspace/services.git',
        revision => 'master',
	    path     => '/tmp/cspace-source/services',
        require  => File[ 'Ensure CollectionSpace source directory' ],
    }
	
    # Download the UI layer source code

    vcsrepo { 'Download UI layer source code':
        ensure   => latest,
        provider => 'git',
        source   => 'https://github.com/collectionspace/ui.git',
        revision => 'master',
	    path     => '/tmp/cspace-source/ui',
        require  => File[ 'Ensure CollectionSpace source directory' ],
    }
		
	# ---------------------------------------------------------
	# Build and deploy CollectionSpace's layers
	# ---------------------------------------------------------
	
	$mvn_clean_cmd = 'mvn clean'
	$mvn_clean_install_cmd = "${mvn_clean_cmd} install -DskipTests"
    
    # Build and deploy the Application layer
    
    exec { 'Build and deploy of Application layer source':
	    command => $mvn_clean_install_cmd,
        cwd     => '/tmp/cspace-source/application',
        path    => $exec_paths,
        require => Vcsrepo[ 'Download Application layer source code' ]
    }

    # Build and deploy the Services layer
    
    exec { 'Build of Services layer source':
	    # Command below is a temporary placeholder during development
	    # for the full build (very time consuming)
        command => $mvn_clean_cmd,
        cwd     => '/tmp/cspace-source/services',
        path    => $exec_paths,
        require => Vcsrepo[ 'Download Services layer source code' ],
    }
	
    exec { 'Deploy of Services layer source':
	    # Command below is a temporary placeholder during development
	    # for the full deploy (very time consuming)
        command => 'ant deploy_services_artifacts',
        cwd     => '/tmp/cspace-source/services/services/JaxRsServiceProvider',
        path    => $exec_paths,
        require => [
		    Exec[ 'Build and deploy of Application layer source' ],
		    Exec[ 'Build of Services layer source' ],
		],
    }
	
	# There is currently no UI layer build required: the tarball of the
	# CollectionSpace Tomcat server folder contains a prebuilt UI layer.

}

