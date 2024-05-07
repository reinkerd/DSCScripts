# Run this configuration like this: ./<this file>.ps1 
# Example: ./rmsreports-deploy.ps1 

param ([switch]$NoCopy)

$Server = 'rmsreports.ss911.net'

# Gonna use some dbatools
import-module dbatools
import-module SQLServer

# Hard-coded source location for modules and other files to copy to target server
$Source = "\\netops08.ss911.net\temp"

# Copy these module files to the source folder from which files are copied to the server 
if (-not $NoCopy) {
    copy-item -path "c:\program files\windowspowershell\modules\ss911" -filter "*.*" -destination "$Source\Modules" -force -Recurse
    copy-item -path "c:\program files\powershell\modules" -filter "*.*" -destination "$Source" -force -Recurse

    # The modules must be copied to the target in order for DSC to be able to use them
    copy-item -path "$source\Modules" -filter "*.*" -Destination "\\$Server\c$\Program Files\WindowsPowerShell" -force -Recurse
}

#Create cim session to pass to start-dscconfiguration
#$option=New-CimSessionOption -UseSsl
$cim=New-CimSession -computername $Server

#Start-DscConfiguration -ComputerName $Server -path ".\SQLServers\" -wait -force -verbose 
Start-DscConfiguration -CimSession $cim -path ".\SQLServers\" -wait -force -verbose

# Set the Server max memory according to a formula
Set-DbatoolsInsecureConnection -SessionOnly
Set-DbaMaxMemory -SqlInstance $Server 

# Hide SQL Instance
Enable-DbaHideInstance -SqlInstance $Server

# Rename SA
Rename-DbaLogin -SqlInstance $Server -login sa -NewLogin sysadminuser

# Add Nelson as a sysadmin
New-DbaLogin -SqlInstance $Server -login 'SS911\EngN' 
Add-DbaServerRoleMember -SqlInstance $Server -login 'SS911\EngN' -ServerRole 'sysadmin' 