param ([string[]]$Servers, [pscredential]$Credential)

# Run this configuration like this: ./AllServer.ps1 -Server <servername> -Credential <credential>

Configuration AllServers
{

    param (
        [string]$Source, # Path of files to be copied to the destination server
        [pscredential]$credential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration, cchoco, ss911, xWebAdministration


    Node $AllNodes.NodeName
    {

        switch ($Node.Environment)
        {
            "D" { $IISEnv="Dev"; $Env = "Development" }
            "Q" { $IISEnv="Test"; $Env = "QualityAssurance" }
            "P" { $IISEnv=""; $Env = "Production" }
            "T" { $IISEnv="Train"; $Env = "Training" }
        }


        SS911_Common Servers
        {
            Source=$Source
            Node=$Node
        }


    }        
}

# Hard-coded source location for modules and other files to copy to target server
$source = "\\itdev46.lesa.net\temp"

# set cim session computer name
if ($null -eq $Credential) { $Credential = Get-Credential -Message "Credentials for DSC to remotely connect" -UserName "$env:userdomain\$env:username" }

# Create MOF files
AllServers -source $source -ConfigurationData Nodes.psd1 -Credential $Credential

copy-item -path "c:\program files\windowspowershell\modules\ss911" -filter "*.*" -destination "$Source\Modules" -force -Recurse

foreach ($Server in $Servers)
{
    # Copy modules to target
    copy-item -path "$source\Modules" -filter "*.*" -Destination "\\$Server\c$\Program Files\WindowsPowerShell" -force -Recurse
    
    #Create cim session to pass to start-dscconfiguration
    $cim=New-CimSession -Credential $Credential -computername $Server

    Start-DscConfiguration -CimSession $cim -path ".\AllServers\" -verbose -force -wait
}

