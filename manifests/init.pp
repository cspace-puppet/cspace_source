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

include cspace_tarball::globals
include cspace_user
include cspace_user::env
include stdlib # for 'validate_array()'

# By convention, CollectionSpace releases are tagged with a v{release number} name;
# e.g. 'v4.0' for release 4.0; hence the prefixing of a 'v' to the 'release_version'
# global below, which is used as the default value for the 'source_code_revision' parameter.

class cspace_source(
  $env_vars             = $cspace_user::env::cspace_env_vars,
  $exec_paths           = [ '/bin', '/usr/bin' ],
  $source_code_revision = '',
  $source_dir_path      = '',
  $user_acct            = $cspace_user::user_acct_name,
  ) {
    
  # Accept the source_code_revision as provided, with a fallback to a revision
  # based on the current release version. This makes it possible for the
  # installer to build from tags that don't follow the naming convention
  # for release versions, while still defaulting to the current release.
  if ( ($source_code_revision == undef) or ( empty($source_code_revision)) ) {
    $source_code_revision = join( [ 'v', $cspace_tarball::globals::release_version ], '' )
  }
    
  # FIXME: Need to qualify this module's resources by OS; this module currently assumes
  # that it's running on a Linux platform.
  
  validate_array($env_vars)
  
  # ---------------------------------------------------------
  # Verify presence of required executables
  # ---------------------------------------------------------
  
  # FIXME: Replace or augment with cross-platform compatible
  # methods for finding executables, including on Windows.
    
  exec { 'Find Ant executable':
    command   => '/bin/sh -c "command -v ant"',
    path      => $exec_paths,
    logoutput => true,
    tag       => [ 'services', 'application', 'ui' ],
  }
  
  exec { 'Find Maven executable':
    command   => '/bin/sh -c "command -v mvn"',
    path      => $exec_paths,
    logoutput => true,
    tag       => [ 'services', 'application', 'ui' ],
  }
  
  # ---------------------------------------------------------
  # Ensure presence of a directory to contain source code
  # ---------------------------------------------------------
  
  # Use the provided source code directory, if available.
  if ( ($source_dir_path != undef) and (! empty($source_dir_path)) ) {
    $cspace_source_dir = $source_dir_path
    # FIXME: Verify the existence of, and (optionally) the requisite
    # access privileges to, the provided source code directory.
  }
  # Otherwise, use a directory in the home directory
  # of the CollectionSpace admin user.
  else {
    $default_cspace_source_dir_name = 'cspace_source'
    # TODO: The following merely uses a hard-coded name for the parent directory which
    # contains user home directories. There may yet be a better (per-platform)
    # approach for identifying the home directory of the CollectionSpace admin user.
    $default_cspace_source_dir = "/home/${user_acct}/${default_cspace_source_dir_name}"
    $cspace_source_dir = $default_cspace_source_dir
  }

  notify{ 'Creating source directory':
    message => "Creating ${cspace_source_dir} directory to hold CollectionSpace source code, if not present ...",
    tag     => [ 'services', 'application', 'ui' ],
  }
  
  file { 'Ensure CollectionSpace source directory':
    ensure  => 'directory',
    path    => $cspace_source_dir,
    owner   => $user_acct,
    tag     => [ 'services', 'application', 'ui' ],
    require => Notify [ 'Creating source directory' ],
  }
  
  # ---------------------------------------------------------
  # Download CollectionSpace source code
  # ---------------------------------------------------------
  
  # The following three groups of actions to download various
  # pieces of CollectionSpace's source code may be run in any order;
  # they are not dependent on one another.
  
  # Download the Application layer source code
  
  # The Services layer deploy is dependent on the Application
  # layer build, so Application layer source code is downloaded
  # even when this manifest is invoked with the 'services' tag. 
    
  notify{ 'Downloading Application layer':
    message => 'Downloading Application layer source code ...',
    tag     => [ 'services', 'application' ],
    require => File [ 'Ensure CollectionSpace source directory' ],
  } 
  
  vcsrepo { 'Download Application layer source code':
    ensure   => latest,
    provider => 'git',
    source   => 'https://github.com/collectionspace/application.git',
    revision => $::source_code_revision,
    path     => "${cspace_source_dir}/application",
    tag      => [ 'services', 'application' ],
    require  => [
      Notify[ 'Downloading Application layer' ]
    ]
  }

  # Download the Services layer source code
  
  notify{ 'Downloading Services layer':
    message  => 'Downloading Services layer source code ...',
    tag      => 'services',
    require  => File [ 'Ensure CollectionSpace source directory' ],
  }
  
  vcsrepo { 'Download Services layer source code':
    ensure   => latest,
    provider => 'git',
    source   => 'https://github.com/collectionspace/services.git',
    revision => $::source_code_revision,
    path     => "${cspace_source_dir}/services",
    tag      => 'services',
    require  => [
      Notify[ 'Downloading Services layer' ]
    ]
  }
  
  # Download the UI layer source code

  notify{ 'Downloading UI layer':
    message => 'Downloading UI layer source code ...',
    tag     => 'ui',
    require => File [ 'Ensure CollectionSpace source directory' ],
  }
  
  vcsrepo { 'Download UI layer source code':
    ensure   => latest,
    provider => 'git',
    source   => 'https://github.com/collectionspace/ui.git',
    revision => $::source_code_revision,
    path     => "${cspace_source_dir}/ui",
    tag      => 'ui',
    require  => [
      Notify[ 'Downloading UI layer' ]
    ]
  }
  
  # ---------------------------------------------------------
  # Change ownership of the source directory, if needed
  # ---------------------------------------------------------
  
  exec { 'Change ownership of source directory to CollectionSpace admin user':
    command   => "chown -R ${user_acct}: ${cspace_source_dir}",
    path      => $exec_paths,
    tag       => [ 'services', 'application', 'ui' ],
    logoutput => on_failure,
    require   => [
      Vcsrepo[ 'Download Application layer source code' ],
      Vcsrepo[ 'Download Services layer source code' ],
      Vcsrepo[ 'Download UI layer source code' ],
    ]
  }
  
  # Note: The 'vcsrepo' resource, starting with version 0.2.0 of 2013-11-13,
  # will intrinsically verify that a Git client exists ("Add autorequire for
  # Package['git']" appears in that version's release notes), so we don't need
  # to independently verify its presence.
  
  # ---------------------------------------------------------
  # Build and deploy CollectionSpace's layers
  # ---------------------------------------------------------
  
  # FIXME: Make it possible to selectively perform builds without
  # running 'mvn clean'.  This will preserve existing build artifacts,
  # if any, and make the build complete faster, at the expense of not
  # performing a reproducible, clean build from scratch each time.
  
  $mvn_cmd                = 'mvn'
  $mvn_clean_phase        = 'clean'
  $mvn_install_phase      = 'install'
  $mvn_no_tests_arg       = '-DskipTests'
  $mvn_recreate_dbs_arg   = '-Drecreate_db=true'
  $mvn_clean_cmd          = "${mvn_cmd} ${mvn_clean_phase}"
  $mvn_clean_install_cmd  = "${mvn_cmd} ${mvn_clean_phase} ${mvn_install_phase} ${mvn_no_tests_arg}"
  $mvn_install_cmd        = "${mvn_cmd} ${mvn_install_phase} ${mvn_no_tests_arg}"
  
  # Build the Services layer
  
  # The Application layer build is dependent on the Services layer build
  # for some of its artifacts - currently for the 'common-api' module -
  # so the Services layer needs to be built before the Application layer.
  #
  # This will generate those Services artifacts in the local Maven repository,
  # so the Application layer can access them.

  notify{ 'Cleaning Services layer source':
    message => 'Cleaning Services layer source (removing old target directories) ...',
    tag     => [ 'services', 'application' ],
    require => [
      Exec[ 'Find Ant executable' ],
      Exec[ 'Find Maven executable' ],
      Exec [ 'Change ownership of source directory to CollectionSpace admin user' ],
    ]
  }
  
  exec { 'Clean Services layer source':
    command     => $mvn_clean_cmd,
    cwd         => "${cspace_source_dir}/services",
    path        => $exec_paths,
    environment => $env_vars,
    user        => $user_acct,
    logoutput   => on_failure,
    tag         => [ 'services', 'application' ],
    require     => Notify[ 'Cleaning Services layer source' ],
    # Use 'before' here, rather than 'require' in the target resource, in case
    # this 'clean-specific' resource might not be run during all future sequences.
    before      => Notify [ 'Building Services layer' ],
  }
    
  notify{ 'Building Services layer':
    message => 'Building Services layer ...',
    tag     => [ 'services', 'application' ],
    # This action is currently kicked off by the 'before' relationship
    # metaparameter in the Exec [ 'Clean Services layer source' ], above.
  }
  
  exec { 'Build from Services layer source':
    command     => $mvn_install_cmd,
    cwd         => "${cspace_source_dir}/services",
    path        => $exec_paths,
    environment => $env_vars,
    user        => $user_acct,
    logoutput   => on_failure,
    timeout     => 1800, # 1800 seconds; e.g. 30 minutes
    tag         => [ 'services', 'application' ],
    require     => Notify[ 'Building Services layer' ],
  }

  # Build and deploy the Application layer

  # The Services layer deploy is dependent on the Application
  # layer build, so the Application layer build is performed
  # even when this manifest is invoked with the 'services' tag. 
    
  notify{ 'Building Application layer':
    message => 'Building and deploying Application layer ...',
    tag     => [ 'services', 'application' ],
    require => Exec [ 'Build from Services layer source' ],
  }
  
  exec { 'Build and deploy from Application layer source':
    command     => $mvn_clean_install_cmd,
    cwd         => "${cspace_source_dir}/application",
    path        => $exec_paths,
    environment => $env_vars,
    user        => $user_acct,
    logoutput   => on_failure,
    tag         => [ 'services', 'application' ],
    require     => Notify[ 'Building Application layer' ],
  }
  
  # Deploy the Services layer

  notify{ 'Deploying Services layer':
    message => 'Deploying Services layer ...',
    tag     => 'services',
    require => Exec[ 'Build and deploy from Application layer source' ],
  }
  
  exec { 'Deploy from Services layer source':
    # Command and cwd below are a temporary substitute during development
    # in place of a full deploy (which can be very time consuming):
    # command     => 'ant deploy_services_artifacts',
    # cwd         => "${cspace_source_dir}/services/services/JaxRsServiceProvider",
    command     => 'ant deploy',
    cwd         => "${cspace_source_dir}/services",
    path        => $exec_paths,
    environment => $env_vars,
    user        => $user_acct,
    logoutput   => on_failure,
    timeout     => 1800, # 1800 seconds; e.g. 30 minutes
    tag         => 'services',
    require     => Notify[ 'Deploying Services layer' ],
  }
  
  notify{ 'Creating databases':
    message => 'Creating databases ...',
    tag     => 'services',
    require => Exec[ 'Deploy from Services layer source' ],
  }
  
  exec { 'Create databases from Services layer source':
    command     => "ant create_db $mvn_recreate_dbs_arg",
    cwd         => "${cspace_source_dir}/services",
    path        => $exec_paths,
    environment => $env_vars,
    user        => $user_acct,
    logoutput   => on_failure,
    tag         => 'services',
    require     => Notify[ 'Creating databases' ],
  }
  
  notify{ 'Initializing default user accounts':
    message => 'Initializing default user accounts and permissions ...',
    tag     => 'services',
    require => Exec[ 'Create databases from Services layer source' ],
  }
  
  exec { 'Initialize default user accounts from Services layer source':
    command     => 'ant import',
    cwd         => "${cspace_source_dir}/services",
    path        => $exec_paths,
    environment => $env_vars,
    user        => $user_acct,
    logoutput   => on_failure,
    tag         => 'services',
    require     => Notify[ 'Initializing default user accounts' ],
  }
  
  # There is currently no UI layer build required: the tarball of the
  # CollectionSpace Tomcat server folder contains a prebuilt UI layer.

}

