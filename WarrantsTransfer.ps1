#
# Run this configuration like this
# Change directory to app folder Ex: c:\workingfoldertfs\servers\buildscripts
# Run in powershell: ./<this file>.ps1 - Example: ./WarrantsTransfer.ps1  

# Hard-coded source location for modules and other files to copy to target server
#$Source = "\\nas01.lesa.net\staff\it\network\powershell\dscserversource"
$Source = "\\itdev46.lesa.net\temp"
$Server = "WarrantsTransfer01.ss911.net"

$Nodes = @{
    AllNodes = @(
        @{ 
            NodeName="*" 
            psdscallowplaintextpassword = $true
            PSDscAllowDomainUser=$true
        },
         @{
            NodeName=$Server
            Environment="P"
            Administrators="LESA\LESAApp"
            AutoLogonAccount="lesa\lseaapp"
            AutoLogonPassword="lesaapp"
         }
     )
}


####################################################################################
# Configuration

Configuration AppServers
{

    param (
        [string]$Source # Path of files to be copied to the destination server
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration, ss911


    Node $AllNodes.NodeName
    {

        ####################################################################################
        # Common Settings

        SS911_Common Servers  
        {
            Source=$Source
            Node=$Node
        }



        ####################################################################################
        # Autorun Apps

        ss911_AutoRunApp DVOUpload   
        {
            Ensure="Present"
            Login="lesa\lesaapp"
            Application="dvoupload.exe" 
            Path="c:\program files\warrantsuploaddvo"
        }

        ss911_AutoRunApp WarrantsUpload  
        {
            Ensure="Present"
            Login="lesa\lesaapp"
            Application="warrantupload.exe"
            Path="C:\Program Files\WarrantUpload"
        }

        ss911_AutoRunApp WarrantAttachmentService  
        {
            Ensure="Present"
            Login="lesa\warrantsattachments"
            Application="warrantattachmentservice.exe"
            Path="C:\LESA\WarrantAttachmentService"
        }


    } # End Node
} # End Configuration


# Create MOF files
AppServers -Source $Source -ConfigurationData $Nodes

copy-item -path "c:\program files\windowspowershell\modules\ss911" -filter "*.*" -destination "$Source\Modules" -force -Recurse

#if ($null -eq $Credential) { $Credential = Get-Credential -Message "Credentials for DSC to remotely connect" -UserName "$env:userdomain\$env:username" }
    
# Copy modules to target
copy-item -path "$source\Modules" -filter "*.*" -Destination "\\$Server\c$\Program Files\WindowsPowerShell" -force -Recurse

#Create cim session to pass to start-dscconfiguration
$cim=New-CimSession -computername $Server

Start-DscConfiguration -CimSession $cim -path ".\AppServers\" -verbose -force -wait

# Log on as WarrantsAttachments
