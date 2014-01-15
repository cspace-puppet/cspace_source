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
#  servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
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

include cspace_user
include cspace_user::env
include stdlib # for 'validate_array()'

class cspace_source( $env_vars = $cspace_user::env::cspace_env_vars, $exec_paths = [ '/bin', '/usr/bin' ], $source_dir_path = undef, $user_acct = $cspace_user::user_acct_name ) {
  
  validate_array($env_vars)
  
  # FIXME: Need to qualify by OS; this module currently assumes
  # that it's running on a Linux platform
  
  # ---------------------------------------------------------
  # Verify presence of required executables
  # ---------------------------------------------------------
  
  # FIXME: Replace or augment with cross-platform compatible
  # methods for finding executables, including on Windows.
    
  notify{ 'Checking for build tools':
    message => 'Checking for availability of Ant and Maven build tools ...',
    tag     => [ 'services', 'application', 'ui' ],
    before  => [
        Exec [ 'Find Ant executable' ],
        Exec [ 'Find Maven executable' ],
    ],
  }
  
  exec { 'Find Ant executable':
    command   => '/bin/sh -c "command -v ant"',
    path      => $exec_paths,
    logoutput => true,
    tag       => [ 'services', 'application', 'ui' ],
    before => Notify[ 'Creating source directory' ],
  }
  
  exec { 'Find Maven executable':
    command   => '/bin/sh -c "command -v mvn"',
    path      => $exec_paths,
    logoutput => true,
    tag       => [ 'services', 'application', 'ui' ],
    before => Notify[ 'Creating source directory' ],
  }
  
  # Note: The 'vcsrepo' resource, starting with version 0.2.0 of 2013-11-13,
  # will intrinsically verify that a Git client exists ("Add autorequire for
  # Package['git']"), so we don't need to independently verify its presence.
  
  # ---------------------------------------------------------
  # Ensure presence of a directory to contain source code
  # ---------------------------------------------------------
  
  # Use the provided source code directory, if available.
  if $source_dir_path != undef {
    $cspace_source_dir = $source_dir_path
    # FIXME: Verify the existence of, and (optionally) the requisite
    # access privileges to, the provided source code directory.
  }
  # Otherwise, use a directory in the home directory
  # of the CollectionSpace admin user.
  else {
    $default_cspace_source_dir_name = 'cspace-source'
    # FIXME: Hard-coded home directory location; could use $HOME if available
    $default_cspace_source_dir = "/home/${user_acct}/${default_cspace_source_dir_name}"
    $cspace_source_dir = $default_cspace_source_dir
  }

  notify{ 'Creating source directory':
    message => "Creating ${cspace_source_dir} directory to hold CollectionSpace source code, if not present ...",
    tag     => [ 'services', 'application', 'ui' ],
    before  => File [ 'Ensure CollectionSpace source directory' ],
  }
  
  file { 'Ensure CollectionSpace source directory':
    ensure  => 'directory',
    path    => $cspace_source_dir,
    owner   => $user_acct,
    tag     => [ 'services', 'application', 'ui' ],
  }
  
  # ---------------------------------------------------------
  # Download CollectionSpace source code
  # ---------------------------------------------------------
  
  # Download the Application layer source code
  
  # The Services layer build is dependent on the Application
  # layer build, so Application layer source code is downloaded
  # even when this manifest is invoked with the 'services' tag. 
    
  notify{ 'Downloading Application layer':
    message => 'Downloading Application layer source code ...',
    tag     => [ 'services', 'application' ],
    before  => Vcsrepo [ 'Download Application layer source code' ],
    require => File [ 'Ensure CollectionSpace source directory' ],
  }
  
  vcsrepo { 'Download Application layer source code':
    ensure   => latest,
    provider => 'git',
    source   => 'https://github.com/collectionspace/application.git',
    revision => 'master',
    path     => "${cspace_source_dir}/application",
    tag      => [ 'services', 'application' ],
    require  => File[ 'Ensure CollectionSpace source directory' ],
  }

  # Download the Services layer source code
  
  notify{ 'Downloading Services layer':
    message => 'Downloading Services layer source code ...',
    tag     => 'services',
    before  => Vcsrepo [ 'Download Services layer source code' ],
    require  => File [ 'Ensure CollectionSpace source directory' ],
  }
  
  vcsrepo { 'Download Services layer source code':
    ensure   => latest,
    provider => 'git',
    source   => 'https://github.com/collectionspace/services.git',
    revision => 'master',
    path     => "${cspace_source_dir}/services",
    tag      => 'services',
    require  => File [ 'Ensure CollectionSpace source directory' ],
  }
  
  # Download the UI layer source code

  notify{ 'Downloading UI layer':
    message => 'Downloading UI layer source code ...',
    tag     => 'ui',
    before  => Vcsrepo [ 'Download UI layer source code' ],
    require => File [ 'Ensure CollectionSpace source directory' ],
  }
  
  vcsrepo { 'Download UI layer source code':
    ensure   => latest,
    provider => 'git',
    source   => 'https://github.com/collectionspace/ui.git',
    revision => 'master',
    path     => "${cspace_source_dir}/ui",
    tag      => 'ui',
    require  => File[ 'Ensure CollectionSpace source directory' ],
  }
  
  # ---------------------------------------------------------
  # Change ownership of the source directory, if needed
  # ---------------------------------------------------------
  
  exec { 'Change ownership of source directory to CollectionSpace admin user':
    command   => "chown -R ${user_acct}: ${cspace_source_dir}",
    path      => $exec_paths,
    tag       => [ 'services', 'application', 'ui' ],
    # TODO: There may be a better way to do this; 'subscribe'-ing
    # to each layer's Vcsrepo resource didn't work here as intended.
    before    => [
      Notify[ 'Building Application layer' ],
      Notify[ 'Building Services layer' ],
    ]
  }
  
  # ---------------------------------------------------------
  # Build and deploy CollectionSpace's layers
  # ---------------------------------------------------------
  
  $mvn_clean_cmd = 'mvn clean'
  $mvn_clean_install_cmd = "${mvn_clean_cmd} install -DskipTests"
  
  # Build and deploy the Application layer

  # The Services layer build is dependent on the Application
  # layer build, so the Application layer build is performed
  # even when this manifest is invoked with the 'services' tag. 
    
  notify{ 'Building Application layer':
    message => 'Building and deploying Application layer ...',
    tag     => [ 'services', 'application' ],
    before  => Exec [ 'Build and deploy via Application layer source' ],
    require => Vcsrepo[ 'Download Application layer source code' ],
  }
  
  exec { 'Build and deploy via Application layer source':
    command     => $mvn_clean_install_cmd,
    cwd         => "${cspace_source_dir}/application",
    path        => $exec_paths,
    environment => $env_vars,
    user        => $user_acct,
    logoutput   => on_failure,
    tag         => [ 'services', 'application' ],
    require     => [
      Exec[ 'Find Maven executable' ],
      Vcsrepo[ 'Download Application layer source code' ],
    ],
  }

  # Build and deploy the Services layer
  
  notify{ 'Building Services layer':
    message => 'Building Services layer ...',
    tag     => 'services',
    before  => Exec [ 'Build via Services layer source' ],
    require => Vcsrepo[ 'Download Services layer source code' ],
  }
  
  exec { 'Build via Services layer source':
    # Command below is a temporary placeholder during development
    # for the full build (very time consuming)
    command     => $mvn_clean_cmd,
    cwd         => "${cspace_source_dir}/services",
    path        => $exec_paths,
    environment => $env_vars,
    user        => $user_acct,
    logoutput   => true,
    tag         => 'services',
    require     => [
      Exec[ 'Find Maven executable' ],
      Vcsrepo[ 'Download Services layer source code' ],
    ],
  }
  
  notify{ 'Deploying Services layer':
    message => 'Deploying Services layer ...',
    tag     => 'services',
    before  => Exec [ 'Deploy via Services layer source' ],
    require => Exec[ 'Build via Services layer source' ],
  }
  
  exec { 'Deploy via Services layer source':
    # Command below is a temporary placeholder during development
    # for the full deploy (very time consuming)
    # command     => 'ant deploy_services_artifacts',
    # cwd         => "${cspace_source_dir}/services/services/JaxRsServiceProvider",
    command     => 'ant deploy',
    cwd         => "${cspace_source_dir}/services",
    path        => $exec_paths,
    environment => $env_vars,
    user        => $user_acct,
    logoutput   => true,
    timeout     => 900, # 900 seconds; e.g. 15 minutes
    tag         => 'services',
    require     => [
      Exec[ 'Find Ant executable' ],
      Exec[ 'Build and deploy via Application layer source' ],
      Exec[ 'Build via Services layer source' ],
    ],
  }
  
  notify{ 'Creating databases':
    message => 'Creating databases ...',
    tag     => 'services',
    before  => Exec [ 'Create databases via Services layer source' ],
    require => Exec[ 'Deploy via Services layer source' ],
  }
  
  exec { 'Create databases via Services layer source':
    command     => 'ant create_db',
    cwd         => "${cspace_source_dir}/services",
    path        => $exec_paths,
    environment => $env_vars,
    user        => $user_acct,
    logoutput   => on_failure,
    tag         => 'services',
    require     => [
      Exec[ 'Find Ant executable' ],
      Exec[ 'Build and deploy via Application layer source' ],
      Exec[ 'Build via Services layer source' ],
      Exec[ 'Deploy via Services layer source' ],
    ],
  }
  
  notify{ 'Initializing default user accounts':
    message => 'Initializing default user accounts and permissions ...',
    tag     => 'services',
    before  => Exec [ 'Initialize default user accounts via Services layer source' ],
    require => Exec[ 'Create databases via Services layer source' ],
  }
  
  exec { 'Initialize default user accounts via Services layer source':
    command     => 'ant import',
    cwd         => "${cspace_source_dir}/services",
    path        => $exec_paths,
    environment => $env_vars,
    user        => $user_acct,
    logoutput   => true,
    tag         => 'services',
    require     => [
      Exec[ 'Find Ant executable' ],
      Exec[ 'Build and deploy via Application layer source' ],
      Exec[ 'Build via Services layer source' ],
      Exec[ 'Deploy via Services layer source' ],
      Exec[ 'Create databases via Services layer source' ],
    ],
  }
  
  # There is currently no UI layer build required: the tarball of the
  # CollectionSpace Tomcat server folder contains a prebuilt UI layer.

}

