#
# Author:: Joshua Sierles <joshua@37signals.com>
# Author:: Joshua Timberman <joshua@opscode.com>
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: nagios
# Recipe:: client
#
# Copyright 2009, 37signals
# Copyright 2009-2010, Opscode, Inc
# Copyright 2011, Dell, Inc
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

# Base filter for our environment
env_filter = " AND environment:#{node[:nagios][:config][:environment]}"

# Find the provisioner ip # Assume provisioner is monitored by my nagios server
nodes = search(:node, "roles:provisioner-server#{env_filter}")

# Get a list of provisioner addresses, if the provisioner is up by now.
if nodes and not nodes.empty?
  prov_addresses = nodes.map do |n| 
    n = node if node.name == n.name
    Nagios::Evaluator.get_value_by_type(n, :admin_ip_eval) 
  end
  # The master admin node is the first one in the list
  provisioner_ip =  prov_addresses[0]
  admin_interface = Nagios::Evaluator.get_value_by_type(node, :admin_interface_eval)
else
  provisioner_ip = admin_interface = nil
end

# Get the DNS domain name
domain_name = node[:dns][:domain]

# Create a list of monitoring hosts (filter duplicate ip's in the list)
dup_list = Hash.new
mon_host = Array.new
search(:node, "roles:nagios-server#{env_filter}") do |n|
  ip = Nagios::Evaluator.get_value_by_type(n, :admin_ip_eval)
  next if ip.nil?
  if (!dup_list.has_key?(ip))
    mon_host << ip
    dup_list[ip] = ip
  end
end

include_recipe "nagios::common"

# Package/plugin install list
case node[:platform]
when "ubuntu","debian"
  nrpe_svc_name = "nagios-nrpe-server"
  plugin_dir = "/usr/lib/nagios/plugins"
  lib64 = ""
when "redhat","centos"
  nrpe_svc_name = "nrpe"
  plugin_dir = "/usr/lib64/nagios/plugins"
  lib64 = "64"
when "suse"
  nrpe_svc_name = "nrpe"
  plugin_dir = "/usr/lib/nagios/plugins"
  lib64 = "64"
end

#save for other recipes that might contribute plugins.
node["nagios"]["plugin_dir"] = plugin_dir

if lib64 == ""
  bash "Fix nrpe startup script" do
    code <<-'EOH'
killall nrpe
sed -ie "s/\(.*start_daemon.*\)/\1\n\tpidof nrpe > \$PIDDIR\/nrpe.pid/g" /etc/init.d/nagios-nrpe-server
EOH
    not_if "grep -q pidof /etc/init.d/nagios-nrpe-server"
  end
end

# Set directory ownership and permissions
remote_directory plugin_dir do
  source "plugins"
  owner "nagios"
  group "nagios"
  mode 0755
  files_mode 0755
end

# NTP server setup
ntp_servers = node[:ntp][:ntp_servers] unless node[:ntp].nil? or node[:ntp][:ntp_servers].nil? or node[:ntp][:ntp_servers].empty?
ntp_servers = "127.0.0.1" if node[:ntp].nil? or node[:ntp][:ntp_servers].nil? or node[:ntp][:ntp_servers].empty?

#### setup variables for the different components   

own_admin_ip = Chef::Recipe::Barclamp::Inventory.get_network_by_type(node, "admin").address

# common
vars = { :lib64 => lib64, :mon_host => mon_host, :provisioner_ip => provisioner_ip, :domain_name => domain_name, :admin_interface => admin_interface, :plugin_dir => plugin_dir, :own_admin_ip => own_admin_ip}
# ntp
vars.merge!({:ntp_servers => ntp_servers})
 
template "/etc/nagios/nrpe.cfg" do
  source "nrpe.cfg.erb"
  owner "nagios"
  group "nagios"
  mode "0644"
  variables(vars)
  notifies :restart, "service[nagios-nrpe-server]"
end

# Set file ownership and permissions
file "#{plugin_dir}/check_dhcp" do
  mode "4755"
  owner "root"
  group "root"
end

# Set file ownership and permissions
file "#{plugin_dir}/check_apt" do
  mode "4755"
  owner "root"
  group "root"
end

# Service startup definition
service "nagios-nrpe-server" do
  service_name nrpe_svc_name
  action :enable
  supports :restart => true, :reload => true
end

# Fix rabbit tests
bash "replace parts of alertness tools" do
  code <<-'EOH'
sed -ie "s/Management: Web UI/RabbitMQ Management/g" /usr/lib/nagios/plugins/check_rabbitmq_aliveness
exit 0
EOH
  action :run
end


