####################################################################################
#
# Configuration
#

Configuration AppServers
{

    param (
        [string]$Source # Path of files to be copied to the destination server
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration, ss911, cchoco, xWebAdministration 

    Node $AllNodes.NodeName
    {

        switch ($Node.Environment)
        {
            "D" { $IISEnv="Dev"; $Env = "Development" }
            "Q" { $IISEnv="Test"; $Env = "QualityAssurance" }
            "P" { $IISEnv=""; $Env = "Production" }
            "T" { $IISEnv="Train"; $Env = "Training" }
        }

        ####################################################################################
        #
        # Common Settings
        #

        SS911_Common Servers
        {
            Source=$Source
            Node=$Node
        }


        ###################################################################################################################
        #
        # Choco Installs
        #

        # ASP .Net Core Runtime - includes Shared Framework - Currently version 7.0.2
        cChocoPackageInstaller ASPDotNetCoreRunTime
        {
            DependsOn="[SS911_Common]Servers"
            Name="dotnet-aspnetruntime"
            Ensure="Present"
        }

        # Java 8 
        cChocoPackageInstaller Java8
        {
            Name="jdk8"
            Ensure="Present"
        }

        # Putty 
        cChocoPackageInstaller Putty
        {
            Name="putty"
            Ensure="Present"
        }

        # Untested as of 11/14/2023
        cChocoPackageInstaller DACFramework140
        {
            Name="sql2017-dacframework"
            chocoParams = "Forcex86"  # 32-bit install
            Ensure="Present"
        }


        # FileZilla
        cChocoPackageInstaller FileZilla
        {
            Name="filezilla"
            Ensure="Present"
        }


        ###################################################################################################################
        #
        # Files, shares and permissions
        #

        # Distribution Folder

        File DistributionFolder
        {
            DestinationPath="C:\DistributionFolder"
            Type="Directory"
            Ensure="Present"
        }

        ss911_smbshare DistributionFolderShare
        {
            DependsOn="[File]DistributionFolder"
            ShareName="DistributionFolder"
            SharePath="C:\DistributionFolder"
            Ensure="Present"
        }

        # Temp Folder

        File Temp
        {
            DestinationPath="c:\Temp"
            Type="Directory"
            Ensure="Present"
        }

        # Pawn Folder

        File Pawn
        {
            DestinationPath="c:\Pawn"
            Type="Directory"
            Ensure="Present"
        }

        ss911_smbshare PawnShare
        {
            DependsOn="[File]Pawn"
            ShareName="Pawn"
            SharePath="C:\Pawn"
            Ensure="Present"
        }

        ss911_fileacl PawnPrivs
        {
            DependsOn="[File]Pawn"
            Path="C:\Pawn"
            Ensure="Present"
            ReadAccess="LESA\Devs,LESA\LesaUtilities"
        }

        ###################################################################################################################
        #                                                                                                                 
        # Sybase - Copies folder from source to local Sybase folder and installs drivers
        #

        ss911_Sybase Sybase157   
        { 
            Source=$Source
        }

        
        ###################################################################################################################
        #                                                                                                                 
        # IIS Server                                                                                                      
        #                                                                                                                 

        # Windows Features 

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

        if ($Env -eq "Development") {
            windowsFeature WebAppDev
            {
                Name="Web-App-Dev"
                Ensure="Present"
                IncludeAllSubFeature=$true
            }
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

        windowsFeature MSMQ
        {
            Name="MSMQ"
            Ensure="Present"
        }

        windowsFeature WCFServices
        {
            Name="net-wcf-services45"
            Ensure="Present"
            IncludeAllSubFeature = $true
        }


        # Remove the default web site
        xWebSite DefaultWebSite
        {
            Ensure="Absent"
            Name="Default Web Site"
            DependsOn="[WindowsFeature]WebServer"
        }

        ##############################################################################################
        #
        # Applications
        #
        
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


        ###################################################################################################################
        #                                                                                                                 #
        # Web Sites                                                                                                       #
        #                                                                                                                 #

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
            WriteAccess="LESA\Devs"
        }

        File JindexPath
        {
            DestinationPath="c:\inetpub\wwwroot\Jindex"
            Type="Directory"
            Ensure="Present"

        }

        xWebSite Jindex
        {
            Ensure="Present"
            Name="Jindex"
            DependsOn="[WindowsFeature]WebServer"
            State="Started"
            PhysicalPath="c:\inetpub\wwwroot\Jindex"
            BindingInfo=@(
                @(MSFT_xWebBindingInformation
                {
                    Protocol="HTTP"
                    Port="80"
                    IPAddress=$Node.IPAddress
                    HostName="$($IISEnv)Jindex.lesa.net"
                }
                );
                @(MSFT_xWebBindingInformation
                {
                    Protocol="HTTP"
                    Port="80"
                    IPAddress=$Node.IPAddress
                    HostName="$($IISEnv)Jindex.southsound911.org"
                }
                )
            )
            AuthenticationInfo=MSFT_xWebAuthenticationInformation 
            {
                Anonymous=$true
                Windows=$false
            }
        }


    } # End Node
} # End Configuration

# Hard-coded source location for modules and other files to copy to target server
$Source = "\\itdev46.lesa.net\temp"

# Create MOF files
AppServers -ConfigurationData DataTransferNodes.psd1 -Source $Source
