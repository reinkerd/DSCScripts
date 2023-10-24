param ([Parameter(Mandatory = $true)][String]$Server)

# Hard-coded source location for modules and other files to copy to target server
$Source = "\\itdev46.lesa.net\temp"

# Copy modules to the source module folder
copy-item -path "c:\program files\windowspowershell\modules\ss911" -filter "*.*" -destination "$Source\Modules" -force -Recurse

# Copy modules to target
copy-item -path "$source\Modules" -filter "*.*" -Destination "\\$Server\c$\Program Files\WindowsPowerShell" -force -Recurse

#Create cim session to pass to start-dscconfiguration
$cim=New-CimSession -computername $Server

# Disable WSUS on target - one of the components of the MOF file requires WSUS to be disabled
Invoke-Command -ComputerName $Server -ScriptBlock {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value 0
    Restart-Service "Windows Update" -ErrorAction SilentlyContinue
}

Start-DscConfiguration -CimSession $cim -path ".\AppServers\" -verbose -force -wait

# Enable WSUS on target
Invoke-Command -ComputerName $Server -ScriptBlock {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value 1
    Restart-Service "Windows Update" -ErrorAction SilentlyContinue
}


