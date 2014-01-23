# Cookbook Name:: nagios
# Definition:: nagios_client
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
# Based on nagios_conf, but applies to client side NRPE configuration
#
define :nrpe_conf, :variables => {}  do

  template "/etc/nagios/nrpe.d/#{params[:name]}.cfg" do
      source "#{params[:name]}.cfg.erb"
      mode "0644"
      group node[:nagios][:group]
      owner node[:nagios][:user]
      variables params[:variables]
      notifies :restart, "service[nagios-nrpe-server]"
      backup 0 
    end 
end
