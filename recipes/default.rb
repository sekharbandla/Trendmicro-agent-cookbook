#
# Cookbook::Trendmicro-agent-cookbook
# Recipe:: default
#
# Copyright:: 2017, REAN Cloud LLC, All Rights Reserved.

case node['platform']
when 'debian', 'ubuntu'
	include_recipe '::ubuntu'
	
when 'redhat'
	include_recipe '::redhat'	

when 'windows'
	template 'C:\Users\Administrator\Desktop\properties.ps1' do 
 source 'windows.erb'
end
powershell_script 'myscript' do
 code '. C:\Users\Administrator\Desktop\properties.ps1'
end
end	