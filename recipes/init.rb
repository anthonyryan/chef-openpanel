#
# Author:: anthony ryan <anthony@tentric.com>
# Cookbook Name:: openpanel
#
# Copyright 2014, Anthony Ryan
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# include our runners for command executions
include_recipe "openpanel::runners"

# install apt key from keyserver
apt_repo "openpanel" do
  key_id "#{node[:openpanel][:apt_key_id]}"
  keyserver "#{node[:openpanel][:apt_keyserver]}"
  #key_package "#{node[:openpanel][:apt_key_package]}"
  source_packages "#{node[:openpanel][:apt_source_packages]}"
  url "#{node[:openpanel][:apt_url]}"
  distribution "#{node[:openpanel][:apt_distribution]}"
  components ["#{node[:openpanel][:apt_components]}"]
end

# install default packages, openpanel-minimum
node['openpanel']['defaultpkgs'].each do |install_pkgs|
  package install_pkgs do
    action :install
    ignore_failure true
    notifies :run, 'execute[slow-down]', :immediately
  end
end

# install all the default openpanel modules
node['openpanel']['modules'].each do |install_modules|
  package install_modules do
    action :install
    ignore_failure true
    notifies :run, 'execute[slow-down]', :immediately
  end
end

# install all the site based openpanel modules if we run a specific layer
node['openpanel']['sitemodules'].each do |install_sitemodules|
  package install_sitemodules do
    action :install
    ignore_failure true
    notifies :run, 'execute[slow-down]', :immediately
  end
end

# perform prep for opsworks apache/php layers
# todo: determine if apache2/php is part of run-list for non-opsworks chef installs
if node[:opsworks][:instance][:layers].include?('php-app') || node[:opsworks][:instance][:layers].include?("web")

  # create the default directory just in case it doesn't exist
  directory "#{node[:openpanel][:apachedir]}/openpanel.d" do
    owner "#{node[:openpanel][:apacheuser]}"
    group "#{node[:openpanel][:apachegroup]}"
    mode 0755
    action :create
    not_if { ::Dir.exists?("#{node[:openpanel][:apachedir]}/openpanel.d") }
    only_if { ::Dir.exists?("#{node[:openpanel][:apachedir]}") }
  end

  # create the log directory just in case it doesn't exist
  directory "#{node[:openpanel][:apachelogdir]}/openpanel/logs" do
    owner "#{node[:openpanel][:apacheuser]}"
    group "#{node[:openpanel][:apachegroup]}"
    mode 0755
    recursive true
    action :create
    not_if { ::Dir.exists?("#{node[:openpanel][:apachelogdir]}/openpanel/logs") }
    only_if { ::Dir.exists?("#{node[:openpanel][:apachelogdir]}") }
  end

  # drop the our provided openpanel template into place
  template 'openpanel.conf' do
    case node[:platform]
    when 'centos','redhat','fedora','amazon'
      path "#{node[:openpanel][:apachedir]}/conf/openpanel.conf"
    when 'debian','ubuntu'
      path "#{node[:openpanel][:apachedir]}/conf-available/openpanel.conf"
    end
    source 'openpanel.conf.erb'
    owner "#{node[:openpanel][:apacheuser]}"
    group "#{node[:openpanel][:apachegroup]}"
    mode 0644
    notifies :restart, resources(:service => 'apache2')
    only_if { ::Dir.exists?("#{node[:openpanel][:apachedir]}") }
  end

  # delete the default template that openpanel creates to avoid issues, keeping conf.d dir
  file "#{node[:openpanel][:apachedir]}/conf.d/openpanel.conf" do
    action :delete
    backup false
    only_if { ::File.exists?("#{node[:openpanel][:apachedir]}/conf.d/openpanel.conf") }
  end

  # create symlink for our openpanel config
  if platform?('debian', 'ubuntu')
    link "#{node[:openpanel][:apachedir]}/conf-enabled/openpanel.conf" do
      to "#{node[:openpanel][:apachedir]}/conf-available/openpanel.conf"
      only_if { ::File.exists?("#{node[:openpanel][:apachedir]}/conf-available/openpanel.conf") }
    end
  end
else
  Chef::Log.info 'No opsworks php layer found. Skipping openpanel apache prep.'
end

# setup our default openpanel-admin password and credentials
execute "openpanel_admin_update" do
  user 'root'
  command <<-EOH
    openpanel-cli -c "'configure user #{node[:openpanel][:username]}' 'set password=#{node[:openpanel][:password]}'"
    openpanel-cli -c "'update user #{node[:openpanel][:username]} emailaddress=#{node[:openpanel][:adminemail]}'"
  EOH
  ignore_failure true
end

# setup our default openpanel server prefs
execute "openpanel_prefs_update" do
  user 'root'
  command <<-EOH
    openpanel-cli -c "'update prefs sendalerts=#{node[:openpanel][:notify]}'"
    openpanel-cli -c "'update prefs mailcontact=#{node[:openpanel][:notifyemail]}'"
    openpanel-cli -c "'update prefs smtphost=#{node[:openpanel][:notifysmtphost]}'"
  EOH
  ignore_failure true
end

# add our existing opsworks users to the openpanel user group
#group 'opsworks'
if node["opsworks"].has_key?("instance")
  existing_ssh_users = load_existing_ssh_users
  existing_ssh_users.each do |id, name|
    execute "openpanel_usergroup_add" do
      Chef::Log.info("Running usermod -a -G #{node[:openpanel][:usergroup]} #{name}")
      user 'root'
      command "usermod -a -G #{node[:openpanel][:usergroup]} #{name}"
      ignore_failure true
    end
  end
end
