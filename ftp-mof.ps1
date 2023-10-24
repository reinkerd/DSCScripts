Configuration FTPServers
{

    param (
        [string]$Source, # Path of files to be copied to the destination server
        [pscredential]$PDFFTPCred
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration, cchoco, ss911, xWebAdministration, SecurityPolicyDsc


    Node $AllNodes.NodeName
    {

        SS911_Common Servers 
        {
            Source=$Source
            Node=$Node
        }

        ###################################################################################################################
        #                                                                                                                 
        # Local User
        #                                                                                                                 

        User PDFFTP 
        {
            UserName                    = 'PDFFTP'
            FullName                    = 'PDFFTP'
            Description                 = 'Account used by the PDFFTP FTP site'
            Password                    = $PDFFTPCred
            Ensure                      = 'Present'
            PasswordChangeRequired      = $false
            PasswordNeverExpires        = $true
            PasswordChangeNotAllowed    = $true
        }

        ###################################################################################################################
        #                                                                                                                 
        # Local Security Policy
        #                                                                                                                 

        UserRightsAssignment LesaUtilities_LogOnAsBatch
        {
            Policy      = "Log_on_as_a_batch_job"
            Identity    = "LESA\LESAUtilities"
            Ensure      = 'Present'
        }


        ###################################################################################################################
        #                                                                                                                 
        # Windows Features                                                                                 
        #                                                                                                                 


        windowsFeature WebServer
        {
            Name="web-webserver"
            Ensure="Present"
        }

        windowsFeature WebScriptingTools
        {
            Name="web-scripting-tools"
            Ensure="Present"
        }

        WindowsFeature WebFTPServer
        {
            Name="web-ftp-server"
            Ensure="Present"
            IncludeAllSubFeature=$true
        }

        windowsFeature Web-Mgmt-Console
        {
            Name="web-mgmt-console"
            Ensure="Present"
        }

        # Delete default web site

        xWebSite DefaultWebSite
        {
            Ensure="Absent"
            Name="Default Web Site"
            DependsOn="[WindowsFeature]WebServer"
        }

    
        ###################################################################################################################
        #                                                                                                                 
        # Specific FTP Sites and Configurations                                                                           
        #                                                                                                                 

        ###################################################################################################################
        #                                                                                                                 
        # PDFFTP site
        #

        if ($Node.PDFFTP)
        {

            ss911_FTPSite PDFFTP  
            {
                DependsOn="[WindowsFeature]WebFTPServer"
                SiteName="PDFFTP"
                Ensure="Present"
                PhysicalPath="\\gondor.lesa.net\webrms\pdfs"
                IPAddress="192.103.180.102"
                ConnectAs="lesa\pdfftp,ADSggre4335gd!!^%#BDasd"
                IPAllow = $false
                IPExceptions = '(IP=192.103.180.0;SubnetMask=255.255.255.0),(IP=192.103.181.0;subnet=255.255.255.0),' +
                                '(IP=162.5.5.82),(IP=162.5.28.11),(IP=162.5.28.20),(IP=162.5.67.144),(IP=192.103.152.40),' +
                                '(IP=192.103.152.41),(IP=192.103.152.143),(IP=192.103.152.146),(IP=192.103.152.147),' +
                                '(IP=192.103.153.68),(IP=192.103.153.69),(IP=192.103.153.244),(IP=192.103.153.70)' +
                                '(IP=192.103.153.71),(IP=192.103.153.72),(IP=192.103.153.73)'
                AllowAnonymous = $false
                UserAccess = "Read" 
            } 
        
            ss911_FTPVirtualFolder Attachments
            {
                DependsOn="[ss911_FTPSite]PDFFTP"
                Site="PDFFTP"
                Ensure="Present"
                Name="Attachments"
                PhysicalPath="\\gondor.lesa.net\webrms\attachments"
                ConnectAs="lesa\pdfftp,ADSggre4335gd!!^%#BDasd"
            }
        }

        ###################################################################################################################
        #                                                                                                                 
        # LESAFTP
        #

        if ($Node.LESAFTP)
        {

            ss911_FTPSite LESAFTP  
            {
                DependsOn="[WindowsFeature]WebFTPServer"
                SiteName="LESAFTP"
                Ensure="Present"
                PhysicalPath="\\gondor.lesa.net\ftp\files"
                IPAddress="192.103.180.105"
                IPAllow = $true
                AllowAnonymous = $true
                AnonymousLogon="lesa\anonymousftp,M34tH34d!"
                UserAccess = "ReadWrite" 
            } 
        } 
    }
}

# Hard-coded source location for modules and other files to copy to target server
$source = "\\itdev46.lesa.net\temp"

$PDFFTPCred = Import-Clixml -path $source\creds\pdfftp.xml

# Create MOF files
FTPServers -PDFFTPCred $PDFFTPCred -source $source -ConfigurationData FTPNodes.psd1  

