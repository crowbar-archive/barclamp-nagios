#
# Author:: Joshua Sierles <joshua@37signals.com>
# Author:: Joshua Timberman <joshua@opscode.com>
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Author:: Greg Alhaus <gregory_althaus@dell.com>
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

# Package/plugin install list
case node[:platform]
when "ubuntu","debian"
  pkg_list=%w{
    nagios-nrpe-server
    nagios-plugins
    nagios-plugins-basic
    nagios-plugins-standard
    libjson-perl
    liblwp-useragent-determined-perl
    libmath-calc-units-perl
    libnagios-plugin-perl
    libnagios-object-perl
    libparams-validate-perl
  }
when "redhat","centos"
  pkg_list=%w{
    nrpe
    nagios-plugins
    nagios-plugins-nrpe
    nagios-plugins-perl
    nagios-plugins-all
  }
when "suse"
  pkg_list=%w{
    nagios-nrpe
    nagios-plugins
    nagios-plugins-nrpe
    nagios-plugins-extras
  }
end

pkg_list.each do |pkg|
  package pkg
end

directory "/etc/nagios" do
  owner "nagios"
  group "nagios"
  mode "0755"
  action :create
end

directory "/etc/nagios/nrpe.d" do
  owner "nagios"
  group "nagios"
  mode "0755"
  action :create
end

