
bash 'linux installation' do
    user 'root'
    code <<-EOH
    #!/bin/bash
    # This script detects platform and architecture, then downloads and installs the matching Deep Security Agent package
    #!/usr/bin/env bash
	wget https://'#{node['Trendmicro-agent-cookbook']['server-address']}':4119/software/agent/Ubuntu_14.04/x86_64/ -O /tmp/agent.deb --no-check-certificate --quiet
	dpkg -i /tmp/agent.deb
	sleep 15
	/opt/ds_agent/dsa_control -r
	/opt/ds_agent/dsa_control -a dsm://'#{node['Trendmicro-agent-cookbook']['server-address']}':4120/ "policyid:1"
    EOH
    action :run
end
  
