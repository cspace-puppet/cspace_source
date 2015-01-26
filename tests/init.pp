# The baseline for module testing used by Puppet Labs is that each manifest
# should have a corresponding test manifest that declares that class or defined
# type.
#
# Tests are then run by using puppet apply --noop (to check for compilation
# errors and view a log of events) or by fully applying the test in a virtual
# environment (to compare the resulting system state to the desired state).
#
# Learn more about module testing here:
# http://docs.puppetlabs.com/guides/tests_smoke.html
#

# Create an instance of this class

# FIXME: the values below should more flexibly be read in from a
# per-node Environment, from configuration files, or from Heira,
# rather than being hard-coded.
#
# See, for instance:
# http://puppetlabs.com/blog/the-problem-with-separating-data-from-puppet-code
# and specifically:
# http://docs.puppetlabs.com/guides/environment.html
# http://docs.puppetlabs.com/hiera/1/

include cspace_environment::execpaths
include cspace_environment::osfamily
include cspace_tarball::globals
include cspace_user
include cspace_user::env

class { 'cspace_source': 
  source_code_rev => $cspace_tarball::globals::release_version,
  # For testing, can temporarily use bleeding-edge master branch
  # or specify a specific branch, tag, or commit by substituting
  # the following; e.g.
  # source_code_rev => 'master',
  # or
  # source_code_rev => 'v4.1.1',
}

notice( "CollectionSpace source code directory is ${cspace_source::cspace_source_dir}" )

