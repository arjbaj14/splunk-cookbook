#
# Cookbook Name:: <name your cookbook>
# Attribute:: default
#
#
#

# <> add appname
if node['roles'].first.nil?
    default['<name>']['splunk']['appname'] = 'NOROLE'
else
    default['<name>']['splunk']['appname'] = node['roles'].first
end

# <> Disable Auto Install : Control if the splunk package gets installed.
default['<name>']['splunk']['disabled'] = false
# <> Give option to download from AWS S3 CLI
default['<name>']['splunk']['aws_cli_download'] = false

# <> Splunk Version to use.
default['<name>']['splunk']['version'] = '6.6.3-e21ee54bc796'

# <> Repo Path: Package repo path.
# Detect if we have a internal repo to use or not.
default['<name>']['splunk']['repopath'] = if node.attribute?('base')
                                         # Use internal repo
                                         "#{node['base']['repohost']}/ias/splunk"
                                       else # Use S3 bucket
                                         's3.amazonaws.com/lms-repo/lms/repos/ias/splunk'
                                       end

# S3 specifics
default['<name>']['splunk']['s3_bucket'] = 'lms-repo'
default['<name>']['splunk']['s3_path'] = 'lms/repos/ias/splunk'

# Assume default use case is a Universal Forwarder (client).
# <> Accept Splunk License: Defaults false
default['<name>']['splunk']['accept_license'] = true
# <> Is Splunk server?: Defaults false
default['<name>']['splunk']['is_server'] = false
# <> Rate Limit: 0 is unlimited, otherwise KBps value.
default['<name>']['splunk']['ratelimit_kilobytessec'] = '0'
# <> Hostname Role prefix
default['<name>']['splunk']['role_prefix'] = true

# User and group details
# <> Splunk Group: The group that splunk will belong to.
default['<name>']['splunk']['group'] = 'splunk'
# <> Splunk Group ID: The group id that splunk group will belong to.
default['<name>']['splunk']['gid'] = 500
# <> Splunk User: The user that splunk will execute as.
default['<name>']['splunk']['owner'] = 'splunk'
# <> Splunk User ID: The user id that the user will be assigned.
default['<name>']['splunk']['uid'] = 500
# <> Splunk User Shell: The shell that will be assigned to the splunk user.
default['<name>']['splunk']['shell'] = '/bin/bash'

# <> Splunk OS paths: Change directories dependent on OS. Defaults to Forwarder.
default['<name>']['splunk']['backup_path'] = case node['platform']
                                          when 'windows'
                                            'C:/Backups/Splunk'
                                          else
                                            '/var/backups/splunk'
                                          end

# <> Splunk RunAsRoot: default to yes due to system logs being limited to root for PCI.
default['<name>']['splunk']['runasroot'] = true

# Deployment Server settings
# <> Splunk Override Deployment Server POD
default['<name>']['splunk']['override_pod'] = nil
# <> Splunk Override Deployment Server DC
default['<name>']['splunk']['override_dc'] = nil
# <> Splunk Default Deployment Server POD
default['<name>']['splunk']['default_pod'] = '<name>'
# <> Splunk Default Deployment Server DC
default['<name>']['splunk']['default_dc'] = 'chandler'
# <> Splunk Default Deployment Server: On the segmented world this is set on the environment level
default['<name>']['splunk']['deployment_server'] = nil
# <> Splunk Default Deployment Servers
default['<name>']['splunk']['deployment_servers'] =
  {
    chandler: {
       <name>: 'splunkewe-deploy-<environment>:8094',
      lodging: 'splunkewe-deploy-<environment>:8092',
      hcom: 'splunkchdeploy.<environment name>:8093',
      cts: 'splunkchdeploy.<environment name>:8091',
      other: 'splunkchdeploy.<environment name>:8089',
    },
    phoenix: {
      <name>: 'splunkewe-deploy-ph.<environment name>:8094',
      lodging: 'splunkewe-deploy-ph.<environment name>:8092',
      hcom: 'splunkphdeploy.<environment name>:8093',
      cts: 'splunkphdeploy.<environment name>:8091',
      other: 'splunkphdeploy.<environment name>:8089',
    },
    karmalab: {
      <name> 'splunkewe-deploy-lab.karmalab.net:8094',
      lodging: 'splunkewe-deploy-lab.karmalab.net:8092',
      hcom: 'splunklabdeploy.karmalab.net:8093',
      cts: 'splunklabdeploy.karmalab.net:8091',
      other: 'splunklabdeploy.karmalab.net:8089',
      lab: 'splunklabdeploy.karmalab.net:8090',
      sea: 'splunk4deploysea.sea.corp.expecn.com:8089',
    },
    corp: {
      sea: 'splunk4deploysea.sea.corp.expecn.com:8089',
    },
    cloud: {
      # Will assume splunkdeploy.<region>.<env>.expedia.com exists.
      ewe: 'splunkdeploy:8089',
    },
  }
