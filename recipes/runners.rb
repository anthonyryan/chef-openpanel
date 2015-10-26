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

# slow down package installs
execute "slow-down" do
  command "sleep 10"
  action :nothing
end

# Automatically update package list
execute "apt-update" do
  command "apt-get clean && apt-get update && sleep 80"
  action :nothing
  ignore_failure true
end

# Automatically remove packages that are no longer needed for dependencies
execute "apt-autoremove" do
  command "apt-get -y autoremove && sleep 20"
  action :nothing
  ignore_failure true
end

# Automatically remove .deb files for packages no longer on your system
execute "apt-autoclean" do
  command "apt-get -y autoclean && sleep 20"
  action :nothing
  ignore_failure true
end
