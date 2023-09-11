

[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node "ProdIISFarm1.ss911.net"
    {
        Settings
        {
            RefreshMode = 'Push'
            RebootNodeIfNeeded = $true
            ConfigurationMode = "ApplyAndMonitor"
            ActionAfterReboot = "ContinueConfiguration"
        }
    }
}

LCMConfig

$server = "labsql1.ss911.net"

if ($cred -eq $null) { $cred = Get-Credential "lesa\reinkerd" }
if ($cim -eq $null) { $cim=New-CimSession -ComputerName $server -Credential $cred }

Set-DscLocalConfigurationManager -path ".\lcmconfig" -cim $cim

Get-DscLocalConfigurationManager -cim $cim | format-table RefreshMode, RebootNodeIfNeeded, ConfigurationMode, ActionAfterReboot