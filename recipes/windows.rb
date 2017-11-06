powershell_script 'Windows Installation' do
  code <<-EOH
  #requires -version 4
  # This script detects platform and architecture, download and install matching Deep Security Agent 10 package
  [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
  $env:LogPath = "$env:appdata\Trend Micro\Deep Security Agent\installer"
  New-Item -path $env:LogPath -type directory
  Start-Transcript -path "$env:LogPath\dsa_deploy.log" -append
  echo "$(Get-Date -format T) - DSA download started"
  (New-Object System.Net.WebClient).DownloadFile("https://'#{node['Trendmicro-agent-cookbook']['server-address']}':4119/software/agent/Windows/x86_64/", "$env:temp\agent.msi")
  echo "$(Get-Date -format T) - Downloaded File Size:" (Get-Item "$env:temp\agent.msi").length
  echo "$(Get-Date -format T) - DSA install started"
  echo "$(Get-Date -format T) - Installer Exit Code:" (Start-Process -FilePath msiexec -ArgumentList "/i $env:temp\agent.msi /qn ADDLOCAL=ALL /l*v `"$env:LogPath\dsa_install.log`"" -Wait -PassThru).ExitCode 
  echo "$(Get-Date -format T) - DSA activation started"
  Start-Sleep -s 50
  & $Env:ProgramFiles"\Trend Micro\Deep Security Agent\dsa_control" -r
  & $Env:ProgramFiles"\Trend Micro\Deep Security Agent\dsa_control" -a dsm://'#{node['Trendmicro-agent-cookbook']['server-address']}':4120/ "policyid:1"
  Stop-Transcript
  echo "$(Get-Date -format T) - DSA Deployment Finished"
  EOH
  action :run 
end                     