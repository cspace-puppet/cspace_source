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
  # source_dir_path => '/add_path_here ...'
        
}
