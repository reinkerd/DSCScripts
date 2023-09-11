param ([string[]]$Servers, [pscredential]$Credential)

# Run this configuration like this: ./AllServer.ps1 -Server <servername> -Credential <credential>

Configuration IISServers
{

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Source
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


        ###################################################################################################################
        #                                                                                                                 #
        # IIS Server                                                                                                      #
        #                                                                                                                 #
        ###################################################################################################################


        #
        # Windows Features 
        #

        windowsFeature WebServer
        {
            Name="web-webserver"
            Ensure="Present"
        }

        windowsFeature WebWindowsAuth
        {
            Name="Web-Windows-Auth"
            Ensure="Present"
        }

        windowsFeature WebScriptingTools
        {
            Name="web-scripting-tools"
            Ensure="Present"
        }

        windowsFeature WebAppDev
        {
            Name="Web-App-Dev"
            Ensure="Present"
            IncludeAllSubFeature=$true
        }

        WindowsFeature WebHttpRedirect
        {
            Name="Web-Http-Redirect"
            Ensure="Present"
        }

        windowsFeature Web-Mgmt-Console
        {
            Name="web-mgmt-console"
            Ensure="Present"
        }

        windowsFeature MSMQ-Directory
        {
            Name="msmq-directory"
            Ensure="Present"
        }

        # Remove the default web site
        xWebSite DefaultWebSite
        {
            Ensure="Absent"
            Name="Default Web Site"
            DependsOn="[WindowsFeature]WebServer"
        }

        cChocoPackageInstaller DotNetCoreWindowsHosting
        {
            DependsOn="[SS911_Common]Servers"
            Name="dotnetcore-windowshosting"
            Ensure="Present"
        }

        cChocoPackageInstaller DotNet5WindowsHosting
        {
            DependsOn="[SS911_Common]Servers"
            Name="dotnet-5.0-windowshosting"
            Ensure="Present"
        }


        ###############################################################################################
        # Folders, shares and permissions

        File DistributionFolder
        {
            DestinationPath="c:\Distributionfolder"
            Type="Directory"
            Ensure="Present"
        }
            
        ss911_smbshare DistFolderShare
        {
            DependsOn="[File]DistributionFolder"
            ShareName="DistributionFolder"
            SharePath="c:\DistributionFolder"
            Ensure="Present"
        }

        switch -regex ($Node.Environment)
        {
            "D|Q" {
                ss911_fileacl DistFolderACL
                {
                    DependsOn="[File]DistributionFolder"
                    Path="c:\DistributionFolder"
                    Ensure="Present"
                    ReadAccess="LESA\Support Center"
                    WriteAccess="LESA\LESA-IT-Developers,LESA\LESAUtilities,LESA\DevBuild,LESA\TFSService"
                }
            }
            "P|T" {
                ss911_fileacl DistFolderACL
                {
                    DependsOn="[File]DistributionFolder"
                    Path="c:\DistributionFolder"
                    Ensure="Present"
                    ReadAccess="LESA\LESA-it-developers,LESA\Support Center"
                    WriteAccess="LESA\Dev Leads,LESA\LESAUtilities"
                }
            }
        }

        File wwwRootFolder
        {
            DestinationPath="C:\inetpub\wwwroot"
            Type="Directory"
            Ensure="Present"
            SourcePath="$Source\wwwroot"
            Recurse=$true
        }
            
        ss911_smbshare InetPubShare
        {
            DependsOn="[windowsFeature]WebServer"
            ShareName="InetPub"
            SharePath="c:\inetpub"
            Ensure="Present"
        }

        ss911_fileacl InetpubFolderACL
        {
            DependsOn="[windowsFeature]WebServer"
            Path="c:\inetpub"
            Ensure="Present"
            ReadAccess="LESA\LESA-it-developers,LESA\Support Center"
        }

        File IISLogsFolder
        {
            DependsOn="[windowsFeature]WebServer"
            DestinationPath="C:\inetpub\logs\LogFiles"
            Type="Directory"
            Ensure="Present"
        }

        ss911_smbshare IISLogsShare
        {
            DependsOn="[windowsFeature]WebServer"
            ShareName="IISLogs"
            SharePath="c:\inetpub\logs\LogFiles"
            Ensure="Present"
        }

        ss911_fileacl IISLogsFolderACL
        {
            DependsOn="[windowsFeature]WebServer"
            Path="c:\inetpub\logs\LogFiles"
            Ensure="Present"
            ReadAccess="LESA\LESA-it-developers"
        }



        #####################################################################################################
        # Copy Sybase files and install driver
        #

        ss911_Sybase Sybase
        {
            Source=$source
        }


        #####################################################################################################
        # Set up web sites.  
        #                                                                                                                 

        if ($Node.Websites.Contains('IncidentMapping'))
        {

            # If this is an Incident Mapping server, just create the CEWS site

            File Projects
            {
                DestinationPath="c:\Projects"
                Type="Directory"
                Ensure="Present"
            }

            ss911_smbshare ProjectsShare
            {
                DependsOn="[File]Projects"
                ShareName="Projects"
                SharePath="c:\Projects"
                Ensure="Present"
            }

            ss911_fileacl ProjectsFolderACL
            {
                DependsOn="[File]Projects"
                Path="c:\Projects"
                Ensure="Present"
                ReadAccess="LESA\LESA-it-developers"
            }

            xWebSite CEWS
            {
                Ensure="Present"
                Name="CEWS"
                DependsOn="[WindowsFeature]WebServer"
                State="Started"
                PhysicalPath="c:\inetpub\wwwroot"
                BindingInfo=@(
                  @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTP"
                        Port="80"
                        IPAddress=$Node.IPAddress

                    }
                  )
                )
                AuthenticationInfo=MSFT_xWebAuthenticationInformation 
                {
                    Anonymous=$true
                    Windows=$false
                }
            }

        } # End Node=IncidentMapping


        # Netmenu website

        if ($Node.WebSites.Contains('Netmenu'))
        {

            # Default IIS server setup.  Create three sites: Netmenu, RMS and StateInterface

            xWebSite Netmenu
            {
                Ensure="Present"
                Name="NetMenu"
                DependsOn="[File]wwwRootFolder","[WindowsFeature]WebServer"
                State="Started"
                PhysicalPath="c:\inetpub\wwwroot\Netmenu"
                BindingInfo=@(
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTP"
                        Port="80"
                        IPAddress=$Node.IPAddress
                        HostName="Netmenu$IISEnv.southsound911.org"

                    }
                    );
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTP"
                        Port="80"
                        IPAddress=$Node.IPAddress
                        HostName="Netmenu$IISEnv"
                    }
                    )
                )
                AuthenticationInfo=MSFT_xWebAuthenticationInformation 
                {
                    Anonymous=$false
                    Windows=$true
                }
            }
        }


        # RMS Website

        if ($Node.Websites.contains('RMS'))
        {
            xWebSite RMS
            {
                Ensure="Present"
                Name="RMS"
                DependsOn="[File]wwwRootFolder","[WindowsFeature]WebServer"
                State="Started"
                PhysicalPath="c:\inetpub\wwwroot\RMS"
                BindingInfo=@(
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTP"
                        Port="80"
                        IPAddress=$Node.IPAddress
                        HostName="RMS$IISEnv.southsound911.org"
                    }
                    );
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTP"
                        Port="80"
                        IPAddress=$Node.IPAddress
                        HostName="RMS$IISEnv"
                    }
                    )
                )
                AuthenticationInfo=MSFT_xWebAuthenticationInformation 
                {
                    Anonymous=$false
                    Windows=$true
                }
            }

        }


        # StateInterface web site

        if ($Node.Websites.contains('StateInterface'))
        {
            xWebSite StateInterface
            {
                Ensure="Present"
                Name="StateInterface"
                DependsOn="[File]wwwRootFolder","[WindowsFeature]WebServer"
                State="Started"
                PhysicalPath="c:\inetpub\wwwroot\StateInterface"
                BindingInfo=@(
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTP"
                        Port="80"
                        IPAddress=$Node.IPAddress
                        HostName="StateInterface$IISEnv.southsound911.org"
                    }
                    );
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTP"
                        Port="80"
                        IPAddress=$Node.IPAddress
                        HostName="StateInterface$IISEnv"
                    }
                    )
                )
                AuthenticationInfo=MSFT_xWebAuthenticationInformation 
                {
                    Anonymous=$false
                    Windows=$true
                }
            }
        }


        # Jindex web site

        if ($Node.Websites.contains('Jindex'))
        {
            xWebSite Jindex
            {
                Ensure="Present"
                Name="Jindex"
                DependsOn="[File]wwwRootFolder","[WindowsFeature]WebServer"
                State="Started"
                PhysicalPath="c:\inetpub\wwwroot\Jindex"
                BindingInfo=@(
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTP"
                        Port="80"
                        IPAddress=$Node.IPAddress
                        HostName="Jindex$IISEnv.lesa.net"
                    }
                    )
                )
                AuthenticationInfo=MSFT_xWebAuthenticationInformation 
                {
                    # Jindex has only anonymous authentication
                    Anonymous=$true
                    Windows=$false
                }
            }
        }
    }        
}

# Hard-coded source location for modules and other files to copy to target server
$source = "\\itdev46.lesa.net\temp"

# set cim session computer name
if ($null -eq $Credential) { $Credential = Get-Credential -Message "Credentials for DSC to remotely connect" -UserName "$env:userdomain\$env:username" }

# Create MOF files
IISServers -source $source -ConfigurationData IISTestNodes.psd1 

<#
copy-item -path "c:\program files\windowspowershell\modules\ss911" -filter "*.*" -destination "$Source\Modules" -force -Recurse

foreach ($Server in $Servers)
{
    # Copy modules to target
    copy-item -path "$source\Modules" -filter "*.*" -Destination "\\$Server\c$\Program Files\WindowsPowerShell" -force -Recurse
    
    #Create cim session to pass to start-dscconfiguration
    $cim=New-CimSession -Credential $Credential -computername $Server

    Start-DscConfiguration -CimSession $cim -path ".\IISServers\" -verbose -force -wait
}

#>