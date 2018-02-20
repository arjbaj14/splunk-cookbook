# Cookbook Name:: splunk-cookbook
# Recipe:: installer_linux
#
# Install Splunk packages and setup all environment requirements for Linux
#

=begin
#<
Install Splunk packages from RPM and configure
It will then validate if the package was downloaded. If it was found, it will then attempt to configure and install Splunk.
The Splunk ohai plugin cookbook will then automatically be triggered.
#>
=end

include_recipe 'splunk-cookbook'

remote_path = node['<OrgName>']['splunk']['full_url'].to_s
package_type = node['<OrgName>']['splunk']['package_type'].to_s
backup_path = "#{node['<OrgName>']['splunk']['backup_path']}/#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}"
deployment_server = splunk_deployment_server

# Add splunk user + group
group node['<OrgName>']['splunk']['group'] do
  not_if 'getent group splunk'
end

user node['<OrgName>']['splunk']['owner'] do
  shell node['<OrgName>']['splunk']['shell']
  home splunk_dir
  system true
  group node['<OrgName>']['splunk']['group']
  not_if 'getent passwd splunk'
end

directory node['<OrgName>']['splunk']['backup_path'] do
  owner node['<OrgName>']['splunk']['owner']
  group node['<OrgName>']['splunk']['group']
  mode 00700
  recursive true
end

directory backup_path do
  owner node['<OrgName>']['splunk']['owner']
  group node['<OrgName>']['splunk']['group']
  mode 00700
  recursive true
  not_if do
    File.exist? "#{splunk_dir}/#{node['<OrgName>']['splunk']['package_type']}-#{node['<OrgName>']['splunk']['version']}-linux-2.6-x86_64-manifest"
  end
end

splunk_user = 'root'
unless node['<OrgName>']['splunk']['runasroot']
  splunk_user = node['<OrgName>']['splunk']['owner']
end

if node['<OrgName>']['splunk']['is_server']
  directory splunk_dir do
    owner splunk_user
    group splunk_user
    mode 00755
  end

  directory "#{splunk_dir}/var" do
    owner node['<OrgName>']['splunk']['owner']
    group node['<OrgName>']['splunk']['group']
    mode 00711
  end

  directory "#{splunk_dir}/var/log" do
    owner node['<OrgName>']['splunk']['owner']
    group node['<OrgName>']['splunk']['group']
    mode 00711
  end

  directory "#{splunk_dir}/var/log/splunk" do
    owner node['<OrgName>']['splunk']['owner']
    group node['<OrgName>']['splunk']['group']
    mode 00700
  end
end

directory "#{splunk_dir}/etc/system/local" do
  owner node['<OrgName>']['splunk']['owner']
  group node['<OrgName>']['splunk']['group']
  mode 00700
  action :create
  recursive true
end

template "#{splunk_dir}/etc/system/local/deploymentclient.conf" do
  source 'local/deploymentclient.conf.erb'
  variables(
    deployment_server: deployment_server
  )
  notifies :restart, 'service[splunk]', :delayed
end

# install package
package package_type do
  source File.join(Chef::Config[:file_cache_path], File.basename(remote_path))
  provider Chef::Provider::Package::Rpm
end

splunk_hostname = if node['<OrgName>']['splunk']['role_prefix']
                    "#{node['<OrgName>']['splunk']['appname']}-#{node['machinename']}"
                  else
                    node['machinename']
                  end

template "#{splunk_dir}/etc/system/local/inputs.conf" do
  source 'local/inputs.conf.erb'
  variables(
    hostname: splunk_hostname
  )
  notifies :restart, 'service[splunk]', :delayed
end

if node['<OrgName>']['splunk']['accept_license']
  # ftr = first time run file created by a splunk install
  execute '<OrgName>-splunk[accept-license-and-enable-boot]' do
    command "#{splunk_cmd} enable boot-start --accept-license --answer-yes"
    only_if { File.exist? "#{splunk_dir}/ftr" }
  end
end

# If we run as splunk user do a recursive chown to that user for all splunk
# files if a few specific files are root owned.
ruby_block '<OrgName>-splunk[fix_file_ownership]' do
  block do
    checkowner = []
    checkowner << "#{splunk_dir}/etc/users"
    checkowner << "#{splunk_dir}/etc/myinstall/splunkd.xml"
    checkowner << "#{splunk_dir}/"
    checkowner.each do |dir|
      next unless File.exist? dir
      if File.stat(dir).uid.eql?(0)
        FileUtils.chown_R(splunk_user, splunk_user, splunk_dir)
      end
    end
  end
  not_if { node['<OrgName>']['splunk']['runasroot'] }
end

if node['init_package'] == 'systemd'
  template '/usr/lib/systemd/system/splunk.service' do
    source 'splunk.systemd.erb'
    mode 00700
    variables(
      splunkdir: splunk_dir,
      runasroot: node['<OrgName>']['splunk']['runasroot']
    )
    notifies :run, 'execute[systemctl-daemon-reload]', :immediately
    notifies :restart, 'service[splunk]', :delayed
  end

  service 'splunk' do
    supports status: true, restart: true
    provider Chef::Provider::Service::Systemd
    action [:enable, :start]
  end

  execute 'systemctl-daemon-reload' do
    command '/bin/systemctl --system daemon-reload'
    action :nothing
  end

else
  template '/etc/init.d/splunk' do
    source 'splunk.init.erb'
    mode 00700
    variables(
      splunkdir: splunk_dir,
      runasroot: node['<OrgName>']['splunk']['runasroot']
    )
    notifies :restart, 'service[splunk]', :delayed
  end

  service 'splunk' do
    supports status: true, restart: true
    provider Chef::Provider::Service::Init
    action :start
  end
end
