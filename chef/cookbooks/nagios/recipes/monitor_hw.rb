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
# Note : This script runs on both the admin and compute nodes.
# 

include_recipe "nagios::common" if node["roles"].include?("nagios-client")
nagios_plugins =node["nagios"]["plugin_dir"]
raid = node["nagios"]["monitor_raid"]
case node[:platform]
when "centos", "redhat"
  ; 
when "ubuntu", "suse"
  raid = nil  # our tools don't work on non-redhat
end


nagios_conf "monitor_hw" do
  variables :raid => raid, :ipmi=> node["nagios"]["monitor_ipmi"]
end
