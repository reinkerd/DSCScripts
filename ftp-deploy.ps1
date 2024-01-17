
param ([string]$Server)

# Hard-coded source location for modules and other files to copy to target server
$source = "\\netops08.ss911.net\temp"

copy-item -path "c:\program files\windowspowershell\modules\ss911" -filter "*.*" -destination "$Source\Modules" -force -Recurse

# Copy modules to target
copy-item -path "$source\Modules" -filter "*.*" -Destination "\\$Server\c$\Program Files\WindowsPowerShell" -force -Recurse
    
#Create cim session to pass to start-dscconfiguration
$cim=New-CimSession -computername $Server

Start-DscConfiguration -CimSession $cim -path ".\FTPServers\" -verbose -force -wait

