# Copyright 2012, Dell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class NagiosService < ServiceObject

  def create_proposal(name)
    @logger.debug("Nagios create_proposal: entering")
    base = super(name)

    enab_raid = Barclamp.find_by_name("raid") != nil
    enab_bios = Barclamp.find_by_name("bios") != nil

    ## all good and fine, but we're not officially suporting HW monitoring for now..
    enab_raid = enab_ipmi = false

    hash = base.current_config.config_hash
    hash["nagios"]["monitor_raid"] = enab_raid
    hash["nagios"]["monitor_ipmi"] = enab_ipmi
    base.current_config.config_hash = hash

    @logger.debug("Nagios create_proposal: exiting. IPMI: #{enab_raid}, RAID: #{enab_ipmi}")
    base
  end

  def transition(inst, name, state)
    @logger.debug("Nagios transition: make sure that network role is on all nodes: #{name} for #{state}")

    #
    # If we are discovering the node, make sure that we add the nagios client or server to the node
    #
    if state == "discovered"
      @logger.debug("Nagios transition: discovered state for #{name} for #{state}")

      prop = @barclamp.get_proposal(inst)

      return [400, "Nagios Proposal is not active"] unless prop.active?

      nodes = prop.active_config.get_nodes_by_role("nagios-server")
      result = true
      if nodes.empty?
        @logger.debug("Nagios transition: make sure that nagios-server role is on first: #{name} for #{state}")
        result = add_role_to_instance_and_node(name, inst, "nagios-server")
        nodes = [ Node.find_by_name(name) ]
      else
        node = Node.find_by_name(name)
        unless nodes.include? node
          @logger.debug("Nagios transition: make sure that nagios-client role is on all nodes but first: #{name} for #{state}")
          result = add_role_to_instance_and_node(name, inst, "nagios-client")
        end
      end

      # Set up the client url
      if result
        # Get the server IP address
        node = nodes.first
        server_ip = node.address("public").addr rescue node.address.addr

        unless server_ip.nil?
          node = Node.find_by_name(name)
          chash = prop.active_config.get_node_config_hash(node)
          chash["crowbar"] = {} if chash["crowbar"].nil?
          chash["crowbar"]["links"] = {} if chash["crowbar"]["links"].nil?
          chash["crowbar"]["links"]["Nagios"] = "http://#{server_ip}/nagios3/cgi-bin/extinfo.cgi?type=1&host=#{node.name}"
          prop.active_config.set_node_config_hash(node, chash)
        end 
      end

      @logger.debug("Nagios transition: leaving from discovered state for #{name} for #{state}")
      a = [200, "" ] if result
      a = [400, "Failed to add role to node"] unless result
      return a
    end

    @logger.debug("Nagios transition: leaving for #{name} for #{state}")
    [200, ""]
  end

end


