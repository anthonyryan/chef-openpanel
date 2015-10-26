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

default[:openpanel][:apt_key_id] = "4EAC69B9"
default[:openpanel][:apt_keyserver] = "keyserver.ubuntu.com"
default[:openpanel][:apt_key_package] = "openpanel-minimal"
default[:openpanel][:apt_source_packages] = "openpanel-minimal"
default[:openpanel][:apt_url] = "http://download.openpanel.com/deb/"
default[:openpanel][:apt_distribution] = "precise"
default[:openpanel][:apt_components] = "main"

default[:openpanel][:log] = "/var/log/openpanel-init.log"
default[:openpanel][:adminemail] = "unknown@myhost.com"
default[:openpanel][:username] = "openpanel-admin"
default[:openpanel][:password] = "openpanel-admin"
default[:openpanel][:usergroup] = "openpaneluser"
default[:openpanel][:home] = "/home/#{node[:openpanel][:user]}"
default[:openpanel][:notify] = "false"
default[:openpanel][:notifyemail] = "unknown@myhost.com"
default[:openpanel][:notifysmtphost] = "127.0.0.1"

case node[:platform]
when 'redhat','centos','fedora','amazon'
  default[:openpanel][:apacheuser] = "www"
  default[:openpanel][:apachegroup] = "www"
  default[:openpanel][:apachepid] = "httpd"
  default[:openpanel][:apachedir] = "/etc/httpd"
  default[:openpanel][:apachelogdir] = "/var/log/httpd"
when 'debian','ubuntu'
  default[:openpanel][:apacheuser] = "www"
  default[:openpanel][:apachegroup] = "www"
  default[:openpanel][:apachepid] = "apache2"
  default[:openpanel][:apachedir] = "/etc/apache2"
  default[:openpanel][:apachelogdir] = "/var/log/apache2"
else
  raise 'Bailing out, unknown platform.'
end

# default openpanel packages to install
default[:openpanel][:defaultpkgs] = [
  'openpanel-minimal'
]

# default openpanel modules we install
default[:openpanel][:modules] = [
  'openpanel-swupd',
  'openpanel-mod-softwareupdate',
  'openpanel-mod-ssh',
  'python-openpanel',
  'openpanel-mod-networking',
  'openpanel-mod-iptables'
]

# site based openpanel modules we install
# to fix openpanel-mod-mysql openpanel-mod-postfixcourier openpanel-mod-spamassassin openpanel-mod-amavis 
# to fix openpanel-mod-ftp openpanel-mod-dnsdomain
if node["opsworks"].has_key?("instance") &&
   node["opsworks"]["instance"].has_key?("layers") &&
   node["opsworks"]["instance"]["layers"].include?("php-app") ||
   node["opsworks"]["instance"]["layers"].include?("web")
     default[:openpanel][:sitemodules] = [
       'logax',
       'openpanel-mod-apache2',
       'openpanel-mod-apacheforward',
       'openpanel-mod-ftp'
     ]
else
     default[:openpanel][:sitemodules] = %w{}
end

require 'etc'
include_attribute 'opsworks_initial_setup::default'

Etc.group do |entry|
  if entry.name == 'opsworks'
    default[:opsworks_gid] = entry.gid
  end
end

include_attribute 'openpanel::customize'
