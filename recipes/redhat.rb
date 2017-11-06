  
bash 'linux installation' do
    user 'root'
    code <<-EOH
    #!/bin/bash
    # This script detects platform and architecture, then downloads and installs the matching Deep Security Agent package
    #!/usr/bin/env bash
	yum -y install wget
	wget https://'#{node['Trendmicro-agent-cookbook']['server-address']}':4119/software/agent/RedHat_EL7/x86_64/ -O /tmp/agent.rpm --no-check-certificate --quiet
	rpm -ihv /tmp/agent.rpm
	sleep 15
	/opt/ds_agent/dsa_control -r
	/opt/ds_agent/dsa_control -a dsm://'#{node['Trendmicro-agent-cookbook']['server-address']}':4120/ "policyid:1"  
    EOH
    action :run
end

