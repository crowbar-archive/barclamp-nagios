#
# Author:: Joshua Sierles <joshua@37signals.com>
# Author:: Joshua Timberman <joshua@opscode.com>
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: nagios
# Attributes:: server
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
def redhat_platform?
  ["redhat","centos","fedora"].include?(platform)
end

def suse_platform?
  ["suse"].include?(platform)
end

set[:nagios][:dir]       = "/etc/nagios3"
set[:nagios][:dir]       = "/etc/nagios" if redhat_platform? or suse_platform?
set[:nagios][:log_dir]   = "/var/log/nagios3"
set[:nagios][:log_dir]   = "/var/log/nagios" if redhat_platform? or suse_platform?
set[:nagios][:cache_dir] = "/var/cache/nagios3"
set[:nagios][:cache_dir] = "/var/log/nagios" if redhat_platform? or suse_platform?
set[:nagios][:state_dir] = "/var/lib/nagios3" 
set[:nagios][:state_dir] = "/var/log/nagios" if redhat_platform?
set[:nagios][:state_dir] = "/var/lib/nagios" if suse_platform?
set[:nagios][:docroot]   = "/usr/share/nagios3/htdocs"
set[:nagios][:docroot]   = "/usr/share/nagios/html" if redhat_platform?
set[:nagios][:docroot]   = "/usr/share/nagios" if suse_platform?
set[:nagios][:config_subdir] = "conf.d"
set[:nagios][:cgi_dir] = "/usr/lib/cgi-bin/nagios3"
set[:nagios][:cgi_dir] = "/usr/lib64/nagios/cgi-bin" if redhat_platform?
set[:nagios][:cgi_dir] = "/usr/lib/nagios/cgi" if suse_platform?
set[:nagios][:resource_file] = "/etc/nagios3/resource.cfg"
set[:nagios][:resource_file] = "/etc/nagios/private/resource.cfg" if redhat_platform?
set[:nagios][:resource_file] = "/etc/nagios/resource.cfg" if suse_platform?
set[:nagios][:nagios_pid] = "/var/run/nagios3/nagios3.pid"
set[:nagios][:nagios_pid] = "/var/run/nagios.pid" if redhat_platform?
set[:nagios][:nagios_pid] = "/var/run/nagios/nagios.pid" if suse_platform?
set[:nagios][:p1_cmd] = "/usr/lib/nagios3/p1.pl"
set[:nagios][:p1_cmd] = "/usr/sbin/p1.pl" if redhat_platform?
set[:nagios][:p1_cmd] = "/usr/lib/nagios/p1.pl" if suse_platform?
set[:nagios][:exec] = "/usr/sbin/nagios3"
set[:nagios][:exec] = "/usr/sbin/nagios" if redhat_platform? or suse_platform?
set[:nagios][:stylesheets] = "/etc/nagios3"
set[:nagios][:stylesheets] = "/usr/share/nagios/html" if redhat_platform?
set[:nagios][:stylesheets] = "/usr/share/nagios/stylesheets" if suse_platform?


default[:nagios][:notifications_enabled]   = 0
default[:nagios][:check_external_commands] = true
default[:nagios][:default_contact_groups]  = %w(admins)
default[:nagios][:sysadmin_email]          = "root@localhost"
default[:nagios][:sysadmin_sms_email]      = "root@localhost"
default[:nagios][:server_auth_method]      = "openid"
default[:nagios][:monitor_ipmi]            = true 
default[:nagios][:monitor_raid]            = false

# This setting is effectively sets the minimum interval (in seconds) nagios can handle.
# Other interval settings provided in seconds will calculate their actual from this value, since nagios works in 'time units' rather than allowing definitions everywhere in seconds

default[:nagios][:templates] = Mash.new
default[:nagios][:interval_length] = 1

# Provide all interval values in seconds
default[:nagios][:default_host][:check_interval]     = 15
default[:nagios][:default_host][:retry_interval]     = 15
default[:nagios][:default_host][:max_check_attempts] = 1
default[:nagios][:default_host][:notification_interval] = 300

default[:nagios][:default_service][:check_interval]     = 60
default[:nagios][:default_service][:retry_interval]     = 15
default[:nagios][:default_service][:max_check_attempts] = 3
default[:nagios][:default_service][:notification_interval] = 1200

default[:nagios][:config] = {}
default[:nagios][:config][:environment] = "nagios-config-default"
default[:nagios][:config][:mode] = "full"

