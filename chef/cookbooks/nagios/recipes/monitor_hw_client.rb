#
# Copyright (c) 2012 Dell Inc.
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
# Author: aabes
# Note : This script runs on node and installs the local plugins and NRPE
# 

if node["roles"].include?("nagios-client") 
  include_recipe "nagios::common" 
  nagios_plugins =node["nagios"]["plugin_dir"]
  raid_type = node["crowbar_wall"]["raid"]["controller"] rescue nil 
  
  # ensure IPMI drivers loaded
  ipmi_load "ipmi_load" do
    settle_time 30
    action :run
  end

  # ensure raid utilities are installed, if we have raid
  include_recipe "raid::install_tools" unless raid_type.nil?

  nrpe_conf "monitor_hw_nrpe" do
      variables( { 
          :plugin_dir => nagios_plugins,
          :raid => raid_type })
  end 

  execute "setuid on sas2ircu" do
    command "chmod g+rsx #{nagios_plugins}/check_sas2ircu"
  end 
  
  execute "setuid on megacli" do
    command "chmod g+rsx #{nagios_plugins}/check_megaraid_sas"
  end 

  execute "setuid on megacli" do
    command "chmod g+rsx #{nagios_plugins}/check_ipmi.pl"
  end 

  # required to have perl scripts that are setuid
  package "perl-suidperl"

end
