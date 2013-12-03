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

$mvn_clean_cmd = 'mvn clean'
$mvn_clean_install_cmd = "${mvn_clean_cmd} install -DskipTests"

class cspace_source( $env_vars, $exec_paths = [ '/bin', '/usr/bin' ] ) {
    
    file { 'Create CollectionSpace source directory':
        ensure => 'directory',
        path   => '/tmp/cspace-source',
    }
    
    # Download and build the Application layer
    
    vcsrepo { '/tmp/cspace-source/application':
        ensure   => latest,
        provider => 'git',
        source   => 'https://github.com/collectionspace/application.git',
        revision => 'master',
        require  => File[ 'Create CollectionSpace source directory' ],
    }
    
    exec { 'Maven clean install of Application layer source':
        command => $mvn_clean_install_cmd,
        cwd     => '/tmp/cspace-source/application',
        path    => $exec_paths,
        require => Vcsrepo[ '/tmp/cspace-source/application' ],
    }

    # Download and build the Services layer
    
    vcsrepo { '/tmp/cspace-source/services':
        ensure   => latest,
        provider => 'git',
        source   => 'https://github.com/collectionspace/services.git',
        revision => 'master',
        require  => File[ 'Create CollectionSpace source directory' ],
    }
    
    # Experiment with setting environment variables on the fly.
    #
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
    
    exec { 'Check values of environment variables':
        command   => 'env',
        path      => $exec_paths,
        logoutput => 'true',
        environment => [ $env_vars ]
        # user      => 'cspace',
    }
    
    exec { 'Maven clean of Services layer source':
        command => $mvn_clean_cmd,
        cwd     => '/tmp/cspace-source/services',
        path    => $exec_paths,
        require => Vcsrepo[ '/tmp/cspace-source/services' ],
    }
	
    exec { 'Ant generation of Services artifacts':
        command => 'ant deploy_services_artifacts',
        cwd     => '/tmp/cspace-source/services/services/JaxRsServiceProvider',
        path    => $exec_paths,
        require => Vcsrepo[ '/tmp/cspace-source/services' ],
    }

    # Download the UI layer

    vcsrepo { '/tmp/cspace-source/ui':
        ensure   => latest,
        provider => 'git',
        source   => 'https://github.com/collectionspace/ui.git',
        revision => 'master',
        require  => File[ 'Create CollectionSpace source directory' ],
    }

}

# Create an instance of this class

# Values below should likely be read from a per-node Environment,
# from configuration files, or from the Heira database, rather than
# hard-coded in a manifest.
#
# See, for instance:
# http://docs.puppetlabs.com/guides/environment.html
# https://gist.github.com/aronr/7763527 (reading YAML files)
# http://docs.puppetlabs.com/hiera/1/
# http://puppetlabs.com/blog/the-problem-with-separating-data-from-puppet-code

class { 'cspace_source': 
    # The values below should be reviewed and changed as needed.
    # In particular, password values below are set to easily-guessable
    # defaults and MUST be changed.
    #
    # The value of JAVA_HOME is not set here; it is assumed to be present
    # in Ant and Maven's environments.
    env_vars   => [ 
	    'ANT_OPTS=-Xmx768m -XX:MaxPermSize=512m',
	    'CATALINA_HOME=/usr/local/share/apache-tomcat-6.0.33',
	    'CATALINA_OPTS=-Xmx1024m -XX:MaxPermSize=384m',
	    'CATALINA_PID=/usr/local/share/apache-tomcat-6.0.33/bin/tomcat.pid',
	    'CSPACE_JEESERVER_HOME=/usr/local/share/apache-tomcat-6.0.33',
		'DB_PASSWORD_CSPACE=cspace',
		'DB_PASSWORD_NUXEO=nuxeo',
		'DB_PASSWORD=postgres',
		'LC_ALL=en_US.UTF-8',
		'MAVEN_OPTS=-Xmx768m -XX:MaxPermSize=512m -Dfile.encoding=UTF-8',
    ],
    exec_paths => [
        '/bin',
        '/usr/bin',
		'/usr/local/bin',
    ],
                
}
