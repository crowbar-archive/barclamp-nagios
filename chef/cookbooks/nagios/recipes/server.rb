#
# Author:: Joshua Sierles <joshua@37signals.com>
# Author:: Joshua Timberman <joshua@opscode.com>
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: nagios
# Recipe:: server
#
# Copyright 2009, 37signals
# Copyright 2009-2010, Opscode, Inc
# Copyright 2011, Opscode, Inc
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

include_recipe "apache2"
include_recipe "apache2::mod_ssl"
include_recipe "apache2::mod_cgi"
include_recipe "apache2::mod_rewrite"
include_recipe "nagios::client"

# Begin recipe transactions
Chef::Log.debug("BEGIN nagios-server")

# Get the config environment filter
env_filter = " AND nagios_config_environment:#{node[:nagios][:config][:environment]}"
Chef::Log.debug("env_filter [" + env_filter.to_s + "]")

# Get the list of nodes
nodes = search(:node, "roles:nagios-client#{env_filter}")
Chef::Log.debug("Node query [" + nodes.to_s + "]")

# Deal with an empty node list
if nodes.empty?
  Chef::Log.debug("No nodes returned from search, using this node so hosts.cfg has data")
  nodes = Array.new
  nodes << node
  Chef::Log.debug("nodes from hosts.cfg [" + nodes.to_s + "]")
else
  # Make sure the server is in the list as well.
  nodes << node unless nodes.include?(node)
end

# Remove nodes that are in the process of going away.
nodes.delete_if { |n| n["state"] == "delete" }

# Get a list of system administration users
sysadmins = search(:users, 'groups:sysadmin')
members = Array.new
sysadmins.each do |s|
  Chef::Log.debug("Add system admin user [" +  s['id'] + "]")
  members << s['id']
end

# Make sure that the nodes have a field "ipaddress" that is the admin address
hosts = {}
platforms = []
nodes.each do |n| 
  ip = Nagios::Evaluator.get_value_by_type(n, :admin_ip_eval)
  hosts[ip] = n unless ip.nil?
  platforms << n[:platform] unless platforms.include?(n[:platform])
end 
# Build a hash of service name to the server fulfilling that role (NOT a list ) 
role_list = Array.new
service_hosts = Hash.new
search(:role, "*:*") do |r|
  role_list << r.name
  search(:node, "roles:#{r.name} #{env_filter}") do |n|
    next if n["state"] == "delete"
    service_hosts[r.name] = n['hostname']
  end
end

# Get the public domain name 
if node[:public_domain]
  public_domain = node[:public_domain]
else
  public_domain = node[:domain]
end
Chef::Log.debug("Public domain [" + public_domain + "]")

# Package install list
do_chk_config = false
case node[:platform]
when "ubuntu","debian"
  pkg_list = %w{ nagios3 nagios-nrpe-plugin nagios-images }
  nagios_svc_name = "nagios3"
when "redhat","centos"
  pkg_list = %w{ nagios php gd }
  nagios_svc_name = "nagios"
  do_chk_config = true
when "suse"
  pkg_list = %w{ nagios }
  nagios_svc_name = "nagios"
  do_chk_config = true
end

pkg_list.each do |pkg|
  package pkg do
    action :upgrade
  end
end

cookbook_file "/usr/sbin/nagios" do
  source "nagios"
  mode "0774"
  owner "root"
  group "root"
  action :create
end

service "nagios3" do
  service_name nagios_svc_name
  supports :status => true, :restart => true, :reload => true
  action :nothing
end

directory "#{node[:nagios][:dir]}/#{node[:nagios][:config_subdir]}" do
  owner "nagios"
  group "nagios"
  mode "0755"
end

nagios_conf "nagios" do
  config_subdir false
end

# Set directory permissions
directory "#{node[:nagios][:dir]}/dist" do
  owner "nagios"
  group "nagios"
  mode "0755"
end

directory node[:nagios][:state_dir] do
  owner "nagios"
  group "nagios"
  mode "0751"
end

directory "#{node[:nagios][:state_dir]}/rw" do
  owner "nagios"
  group node[:apache][:group]
  mode "2710"
end

directory "#{node[:nagios][:state_dir]}/spool" do
  owner "nagios"
  group node[:apache][:group]
  mode "2710"
end

directory "#{node[:nagios][:state_dir]}/spool/checkresults" do
  owner "nagios"
  group node[:apache][:group]
  mode "2710"
end

execute "archive default nagios object definitions" do
  command "mv #{node[:nagios][:dir]}/#{node[:nagios][:config_subdir]}/*_nagios*.cfg #{node[:nagios][:dir]}/dist"
  not_if { Dir.glob(node[:nagios][:dir] + "/#{node[:nagios][:config_subdir]}/*_nagios*.cfg").empty? }
end


file "#{node[:nagios][:dir]}/#{node[:nagios][:config_subdir]}/internet.cfg" do
  action :delete
end
file "#{node[:apache][:dir]}/conf.d/nagios3.conf" do
  action :delete
end
file "#{node[:apache][:dir]}/conf.d/nagios.conf" do
  action :delete
end

case node[:nagios][:server_auth_method]
when "openid"
  include_recipe "apache2::mod_auth_openid"
else
  template "#{node[:nagios][:dir]}/htpasswd.users" do
    source "htpasswd.users.erb"
    owner "nagios"
    group node[:apache][:group]
    mode 0640
    variables(
      :sysadmins => sysadmins
    )
  end
end

apache_site "000-default" do
  enable false
end

if platform?("suse")
  nagios_apache_conf = "#{node[:apache][:dir]}/vhosts.d/nagios3.conf"
else
  nagios_apache_conf = "#{node[:apache][:dir]}/sites-available/nagios3.conf"
end

template nagios_apache_conf do
  source "apache2.conf.erb"
  mode 0644
  variables :public_domain => public_domain
  if ::File.exists?(nagios_apache_conf)
    notifies :reload, resources(:service => "apache2")
  end
end

apache_site "nagios3.conf"

%w{ nagios cgi }.each do |conf|
  nagios_conf conf do
    config_subdir false
  end
end

#
# check_nova_ldap - one day if needed.
#
nova_commands = %w{ check_nova_api check_nova_compute check_nova_network check_nova_rabbit check_nova_scheduler check_nova_volume check_nova_manage }

swift_svcs = %w{swift-object swift-object-auditor swift-object-replicator swift-object-updater} 
swift_svcs =swift_svcs + %w{swift-container swift-container-auditor swift-container-replicator swift-container-updater}
swift_svcs =swift_svcs + %w{swift-account swift-account-reaper swift-account-auditor swift-account-replicator}
swift_svcs =swift_svcs + ["swift-proxy"] 

glance_svcs = %w{glance-api glance-registry}
keystone_svcs = %w{keystone}

ports=%w{keystone-admin keystone-service glance-api glance-registry swift-object swift-container swift-account swift-proxy}

%w{ commands templates timeperiods}.each do |conf|
  nagios_conf conf do
    variables :nova_commands => nova_commands, :svcs => swift_svcs + glance_svcs + keystone_svcs, :ports => ports
  end
end

nagios_conf "services" do
  variables :service_hosts => service_hosts, :platforms => platforms
end

nagios_conf "contacts" do
  variables :admins => sysadmins, :members => members
end

nagios_conf "hostgroups" do
  variables :roles => role_list, :platforms => platforms
end

nagios_conf "hosts" do
  variables :hosts => hosts, :platforms => platforms
end

if do_chk_config
  # Everyone needs chef-client running - redhat doesn't chkconfig this by default.
  bash "Check config nagios" do
    code "/sbin/chkconfig --level 345 nagios on"
    not_if "/sbin/chkconfig --list nagios | grep -q on"
  end
end

mon_hw = node[:nagios][:monitor_raid] or node[:nagios][:monitor_ipmi] rescue false
include_recipe "nagios::monitor_hw" if mon_hw == true

# End of recipe transactions
Chef::Log.debug("END nagios-server")

