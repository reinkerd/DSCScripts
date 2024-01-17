# Run this configuration like this: ./<this file>.ps1 -Server <servername> 
# Example: ./SQL-Deploy.ps1 -Server labsql1.ss911.net 

param ([string]$Server)

# Gonna use some dbatools
import-module dbatools

# Hard-coded source location for modules and other files to copy to target server
$Source = "\\netops08.ss911.net\temp"

# Copy these module files to the source folder from which files are copied to the server 
copy-item -path "c:\program files\windowspowershell\modules\ss911" -filter "*.*" -destination "$Source\Modules" -force -Recurse

# The modules must be copied to the target in order for DSC to be able to use them
copy-item -path "$source\Modules" -filter "*.*" -Destination "\\$Server\c$\Program Files\WindowsPowerShell" -force -Recurse

#Create cim session to pass to start-dscconfiguration
$cim=New-CimSession -computername $Server

Start-DscConfiguration -CimSession $cim -path ".\SQLServers\" -verbose -force -wait 

# Find all .sql files for this server and run against this server
$files = get-childitem -path "$source\$Server" -filter "*.sql"
foreach ($file in $files) {
    Invoke-Sqlcmd -ServerInstance $Server -InputFile "$($file.fullname)"
}

# Set the Server max memory according to a formula
Set-DbaMaxMemory -SqlInstance $Server 