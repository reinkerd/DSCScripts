
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

        cChocoPackageInstaller 7Zip
        {
            Name="sqlserver-odbcdriver"
            Ensure="Present"
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

        ###########################################################################################
        # ScreeningSheets

        File ExtractEmailFromExchangeServer-ScreeningSheets
        {
            DestinationPath="C:\LESA\ExtractEmailFromExchangeServer-ScreeningSheets"
            Type="Directory"
            Ensure="Present"
        }

        ss911_fileacl ExtractEmailFromExchangeServer-ScreeningSheets
        {
            DependsOn = "[File]ExtractEmailFromExchangeServer-ScreeningSheets"
            Path="c:\LESA\ExtractEmailFromExchangeServer-ScreeningSheets"
            Ensure="Present"
            ReadAccess = "LESA\LESA-it-developers"
            WriteAccess="SS911\recordsautomation,LESA\LESAUtilities"
        }

        ###########################################################################################
        # Fingerprints

        File ExtractEmailFromExchangeServer-Fingerprints
        {
            DestinationPath="C:\LESA\ExtractEmailFromExchangeServer-Fingerprints"
            Type="Directory"
            Ensure="Present"
        }

        ss911_fileacl ExtractEmailFromExchangeServer-Fingerprints
        {
            DependsOn="[File]ExtractEmailFromExchangeServer-Fingerprints"
            Path="c:\LESA\ExtractEmailFromExchangeServer-Fingerprints"
            Ensure="Present"
            WriteAccess="SS911\recordsautomation,LESA\LESAUtilities"
        }

        File FingerprintResponse-FingerprintMessage
        {
            DestinationPath="C:\lesa\data\fingerprintresponse"
            Type="Directory"
            Ensure="Present"
        }

        ss911_fileacl FingerprintResponse-FingerprintMessage
        {
            DependsOn="[File]FingerprintResponse-FingerprintMessage"
            Path="C:\lesa\data\fingerprintresponse"
            Ensure="Present"
            WriteAccess="SS911\fingerprintmessage"
        }

        ###########################################################################################
        # ScreeningSheetProcessor

        File ScreeningSheetProcessor
        {
            DestinationPath="C:\LESA\ScreeningSheetProcessor"
            Type="Directory"
            Ensure="Present"
        }

        ss911_fileacl ScreeningSheetProcessor
        {
            DependsOn = "[File]ScreeningSheetProcessor"
            Path="c:\LESA\ScreeningSheetProcessor"
            Ensure="Present"
            WriteAccess="SS911\recordsautomation,LESA\LESAUtilities"
        }

        ###########################################################################################
        # EventLogConsolidator

        File EventLogConsolidator
        {
            DestinationPath="C:\LESA\Data\EventLogConsolidator"
            Type="Directory"
            Ensure="Present"
        }

        ss911_fileacl EventLogConsolidator
        {
            DependsOn = "[File]EventLogConsolidator"
            Path="c:\LESA\Data\EventLogConsolidator"
            Ensure="Present"
            WriteAccess="SS911\recordsautomation,LESA\LESAUtilities,SS911\EventLogConsolidator"
        }

        ###########################################################################################
        # Electronic Turnout

        File ElectronicTurnout
        {
            DestinationPath="C:\Temp"
            Type="Directory"
            Ensure="Present"
        }

        ss911_fileacl ElectronicTurnout
        {
            Path="c:\Temp"
            Ensure="Present"
            WriteAccess="SS911\ElectronicTurnout"
        }

        ###########################################################################################
        # LESADataLogs

        File LESADataLogs
        {
            DestinationPath="C:\LESA\Data\Logs"
            Type="Directory"
            Ensure="Present"
        }

        ss911_fileacl DataLogs
        {
            Path="c:\LESA\Data\Logs"
            Ensure="Present"
            WriteAccess="SS911\recordsautomation,LESA\LESAUtilities,SS911\ScreeningSheets,SS911\EventLogConsolidator"
        }

        ###########################################################################################
        # Warrants

        File Warrants
        {
            DestinationPath="C:\inetpub\wwwroot\records"
            Type="Directory"
            Ensure="Present"
        }

        ss911_fileacl Warrants
        {
            Path="C:\inetpub\wwwroot\records"
            Ensure="Present"
            WriteAccess="SS911\warrants"
        }

        ###################################################################################################################
        #                                                                                                                 #
        # Local Groups                                                                                                    #
        #                                                                                                                 #
        ###################################################################################################################

        ss911_LocalGroup IIS_IUSRS
        {
            Ensure="Present"
            Name="IIS_IUSRS"
            AdGroup="IIS_IUSRS"
            MembersToInclude="SS911\Oscar,SS911\ElectronicTurnout"
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

            File Netmenu
            {
                DestinationPath="C:\inetpub\wwwroot\netmenu"
                Type="Directory"
                Ensure="Present"
            }

            xWebSite Netmenu
            {
                Ensure="Present"
                Name="NetMenu"
                DependsOn="[File]Netmenu","[WindowsFeature]WebServer"
                State="Started"
                PhysicalPath="c:\inetpub\wwwroot\Netmenu"
                BindingInfo=@(
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTPS"
                        Port="443"
                        IPAddress=$Node.IPAddress
                        HostName="Netmenu$IISEnv"
                        CertificateStoreName = "WebHosting"
                        CertificateThumbprint = $Node.CertificateThumbprint
                    }
                    );
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTPS"
                        Port="443"
                        IPAddress=$Node.IPAddress
                        HostName="Netmenu$IISEnv.SouthSound911.org"
                        CertificateStoreName = "WebHosting"
                        CertificateThumbprint = $Node.CertificateThumbprint
                    }
                    );
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTP"
                        Port="80"
                        IPAddress=$Node.IPAddress
                        HostName="LESASystemsService$IISEnv"
                    }
                    );
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTP"
                        Port="80"
                        IPAddress=$Node.IPAddress
                        HostName="LESASystemsService$IISEnv.SouthSound911.org"
                    }
                    );
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTP"
                        Port="80"
                        IPAddress=$Node.IPAddress
                        HostName="LESASystemsService$IISEnv.lesa.net"
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
            File RMS
            {
                DestinationPath="C:\inetpub\wwwroot\rms"
                Type="Directory"
                Ensure="Present"
            }

            xWebSite RMS
            {
                Ensure="Present"
                Name="RMS"
                DependsOn="[File]RMS","[WindowsFeature]WebServer"
                State="Started"
                PhysicalPath="c:\inetpub\wwwroot\RMS"

                BindingInfo=@(
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTPS"
                        Port="443"
                        IPAddress=$Node.IPAddress
                        HostName="RMS$IISEnv"
                        CertificateStoreName = "WebHosting"
                        CertificateThumbprint = $Node.CertificateThumbprint
                    }
                    );
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTPS"
                        Port="443"
                        IPAddress=$Node.IPAddress
                        HostName="RMS$IISEnv.southsound911.org"
                        CertificateStoreName = "WebHosting"
                        CertificateThumbprint = $Node.CertificateThumbprint
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

        # Records Website

        if ($Node.Websites.contains('Records'))
        {

            File Records
            {
                DestinationPath="C:\inetpub\wwwroot\records"
                Type="Directory"
                Ensure="Present"
            }

            xWebSite Records
            {
                Ensure="Present"
                Name="Records"
                DependsOn="[File]Records","[WindowsFeature]WebServer"
                State="Started"
                PhysicalPath="c:\inetpub\wwwroot\Records"

                BindingInfo=@(
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTPS"
                        Port="443"
                        IPAddress=$Node.IPAddress
                        HostName="Records$IISEnv"
                        CertificateStoreName = "WebHosting"
                        CertificateThumbprint = $Node.CertificateThumbprint
                    }
                    );
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTPS"
                        Port="443"
                        IPAddress=$Node.IPAddress
                        HostName="Records$IISEnv.southsound911.org"
                        CertificateStoreName = "WebHosting"
                        CertificateThumbprint = $Node.CertificateThumbprint
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

        if ($Node.Websites.contains('WebRMS'))
        {
            File WebRMS
            {
                DestinationPath="C:\inetpub\wwwroot\webrms"
                Type="Directory"
                Ensure="Present"
            }

            xWebSite WebRMS
            {
                Ensure="Present"
                Name="WebRMS"
                DependsOn="[File]webrms","[WindowsFeature]WebServer"
                State="Started"
                PhysicalPath="c:\inetpub\wwwroot\WebRMS"

                BindingInfo=@(
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTPS"
                        Port="443"
                        IPAddress=$Node.IPAddress
                        HostName="WebRMS$IISEnv"
                        CertificateStoreName = "WebHosting"
                        CertificateThumbprint = $Node.CertificateThumbprint
                    }
                    );
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTPS"
                        Port="443"
                        IPAddress=$Node.IPAddress
                        HostName="WebRMS$IISEnv.southsound911.org"
                        CertificateStoreName = "WebHosting"
                        CertificateThumbprint = $Node.CertificateThumbprint
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

        if ($Node.Websites.contains('REDIRECT'))
        {
            xWebSite REDIRECT
            {
                Ensure="Present"
                Name="REDIRECT"
                DependsOn="[File]wwwRootFolder","[WindowsFeature]WebServer"
                State="Started"
                PhysicalPath="c:\inetpub\wwwroot"

                BindingInfo=@(
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTP"
                        Port="80"
                        IPAddress=$Node.IPAddress
                        HostName="Netmenu$IISEnv.southsound911.org"
                    }
                    )
                )
                AuthenticationInfo=MSFT_xWebAuthenticationInformation 
                {
                    Anonymous=$true
                    Windows=$false
                }
            }

            xWebConfigProperty REDIRECTEnabled
            {
                DependsOn="[xWebSite]REDIRECT"
                WebSitePath="MACHINE/WEBROOT/APPHOST/REDIRECT"
                Filter= "system.webServer/httpRedirect"
                PropertyName="enabled"
                Value='True'
                Ensure='Present'
            }

            xWebConfigProperty REDIRECTDestination
            {
                DependsOn="[xWebSite]REDIRECT"
                WebSitePath="MACHINE/WEBROOT/APPHOST/REDIRECT"
                Filter= "system.webServer/httpRedirect"
                PropertyName="destination"
                Value='https://netmenu.southsound911.org$S$Q'
                Ensure='Present'
            }

            xWebConfigProperty REDIRECTExactDestination
            {
                DependsOn="[xWebSite]REDIRECT"
                WebSitePath="MACHINE/WEBROOT/APPHOST/REDIRECT"
                Filter= "system.webServer/httpRedirect"
                PropertyName="exactDestination"
                Value='True'
                Ensure='Present'
            }

        }

        if ($Node.Websites.contains('WebRMSRedirect'))
        {
            xWebSite WebRMSRedirect
            {
                Ensure="Present"
                Name="WebRMSRedirect"
                DependsOn="[File]wwwRootFolder","[WindowsFeature]WebServer"
                State="Started"
                PhysicalPath="c:\inetpub\wwwroot"

                BindingInfo=@(
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTP"
                        Port="80"
                        IPAddress=$Node.IPAddress
                        HostName="WebRMS$IISEnv.southsound911.org"
                    }
                    )
                )
                AuthenticationInfo=MSFT_xWebAuthenticationInformation 
                {
                    Anonymous=$true
                    Windows=$false
                }
            }

            xWebConfigProperty WebRMSRedirectEnabled
            {
                DependsOn="[xWebSite]WebRMSRedirect"
                WebSitePath="MACHINE/WEBROOT/APPHOST/WEBRMSREDIRECT"
                Filter= "system.webServer/httpRedirect"
                PropertyName="enabled"
                Value='True'
                Ensure='Present'
            }

            xWebConfigProperty WebRMSRedirectDestination
            {
                DependsOn="[xWebSite]WebRMSRedirect"
                WebSitePath="MACHINE/WEBROOT/APPHOST/WEBRMSREDIRECT"
                Filter= "system.webServer/httpRedirect"
                PropertyName="destination"
                Value='https://webrms.southsound911.org$S$Q'
                Ensure='Present'
            }

            xWebConfigProperty WebRMSRedirectExactDestination
            {
                DependsOn="[xWebSite]WebRMSRedirect"
                WebSitePath="MACHINE/WEBROOT/APPHOST/WEBRMSREDIRECT"
                Filter= "system.webServer/httpRedirect"
                PropertyName="exactDestination"
                Value='True'
                Ensure='Present'
            }

        }

        # StateInterface web site

        if ($Node.Websites.contains('StateInterface'))
        {

            File StateInterface
            {
                DestinationPath="C:\inetpub\wwwroot\stateinterface"
                Type="Directory"
                Ensure="Present"
            }

            xWebSite StateInterface
            {
                Ensure="Present"
                Name="StateInterface"
                DependsOn="[File]StateInterface","[WindowsFeature]WebServer"
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
                    );
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTPS"
                        Port="443"
                        IPAddress=$Node.IPAddress
                        HostName="StateInterface$IISEnv"
                        CertificateStoreName = "WebHosting"
                        CertificateThumbprint = $Node.CertificateThumbprint
                    }
                    );
                    @(MSFT_xWebBindingInformation
                    {
                        Protocol="HTTPS"
                        Port="443"
                        IPAddress=$Node.IPAddress
                        HostName="StateInterface$IISEnv.southsound911.org"
                        CertificateStoreName = "WebHosting"
                        CertificateThumbprint = $Node.CertificateThumbprint
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

[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node $AllNodes.NodeName
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

LCMConfig -ConfigurationData IISNodes.psd1

# Hard-coded source location for modules and other files to copy to target server
$source = "\\netops08.ss911.net\temp"

# Create MOF files
IISServers -source $source -ConfigurationData IISNodes.psd1 

