param ([string]$Server)

# Run this configuration like this: ./<this file>.ps1 -Server <servername> 
# Example: /SQL-Deploy.ps1 -Server labsql1.ss911.net 

# Hard-coded source location for modules and other files to copy to target server
$Source = "\\itdev46.lesa.net\temp"

# Copy these module files to the source folder from which files are copied to the server 
copy-item -path "c:\program files\windowspowershell\modules\ss911" -filter "*.*" -destination "$Source\Modules" -force -Recurse

# Copy modules to target
copy-item -path "$source\Modules" -filter "*.*" -Destination "\\$Server\c$\Program Files\WindowsPowerShell" -force -Recurse

#Create cim session to pass to start-dscconfiguration
$cim=New-CimSession -computername $Server

Start-DscConfiguration -CimSession $cim -path ".\SQLServers\" -verbose -force -wait 

if (test-path -path "$source\$Server\lockdown.sql") { Invoke-Sqlcmd -ServerInstance $Server -InputFile "$source\$Server\lockdown.sql" }

