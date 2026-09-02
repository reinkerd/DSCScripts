param ([string]$Server)

[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node $Server
    {
        Settings
        {
            RefreshMode = 'Push'
            RebootNodeIfNeeded = $true
            ConfigurationMode = "ApplyOnly"
            ActionAfterReboot = "ContinueConfiguration"
        }
    }
}

LCMConfig 

Set-DscLocalConfigurationManager -path ".\lcmconfig" -ComputerName $Server

