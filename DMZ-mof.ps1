####################################################################################
# Configuration

Configuration DMZServers
{

    [CmdletBinding()]
    param
    (

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServiceCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SACredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Source
        
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration, cchoco, ss911, SQLServerDSC, xWebAdministration      


    Node $AllNodes.NodeName
    {

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

        File wwwRootFolder
        {
            DestinationPath="C:\inetpub\wwwroot"
            Type="Directory"
            Ensure="Present"
            SourcePath="$Source\wwwroot"
            Recurse=$true
        }
            

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
                    IPAddress="*"
                    #HostName = "devrms.southsound911.org"
                    #CertificateThumbprint = "cbf5f159fc6c3bae9274d80f1ba8e8bfa07f28ed"
                    #CertificateStoreName = "MY"
                    #SslFlags = 1
                }
                )
            )
            AuthenticationInfo=MSFT_xWebAuthenticationInformation 
            {
                Anonymous=$true
                Windows=$false
            }
        }


        ###################################################################################################################
        #                                                                                                                 #
        # SQL Server                                                                                                      #
        #                                                                                                                 #
        ###################################################################################################################

        $SQLPath     = $Node.SQLPath
        $SQLDataPath = $Node.SQLDataPath
        $SQLLogsPath = $Node.SQLLogsPath
        
        #                                                                                                                 
        # File Folders                                                                                                    
        #                                                                                                                 

        File SQLData
        {
            DestinationPath=$SQLDataPath
            Ensure="Present"
            Type="Directory"
        }

        File SQLLogs
        {
            DestinationPath=$SQLLogsPath
            Ensure="Present"
            Type="Directory"
        }

        File Scripts
        {
            DestinationPath="C:\Scripts"
            Ensure="Present"
            Type="Directory"
            SourcePath="$source\Scripts"
            Recurse=$true
        }

        File SQLLocalInstall
        {
            DestinationPath=$SQLPath
            Type="Directory"
            SourcePath="$source\SQL2025"
            Ensure="Present"
            Recurse=$true
        }

        ss911_Sybase Sybase157   
        { 
            Source=$source
        }

        SqlSetup InstallSQL
        {
            InstanceName           = 'MSSQLSERVER'
            Action                 = 'Install'
            Features               = 'SQLENGINE,REPLICATION,FULLTEXT,IS'
            SQLCollation           = 'SQL_Latin1_General_CP1_CI_AS'
            SQLSvcAccount          = $SqlServiceCredential
            SQLSvcStartupType      = 'Automatic'
            AgtSvcAccount          = $SqlServiceCredential
            AgtSvcStartupType      = 'Automatic'
            SQLSysAdminAccounts    = @('SS911\ReinkerD','SS911\Engn')
            InstallSharedDir       = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir    = 'C:\Program Files (x86)\Microsoft SQL Server'
            InstanceDir            = 'C:\Program Files\Microsoft SQL Server'
            SQMReporting           = 'False'
            IsSvcStartupType       = 'Automatic'
            InstallSQLDataDir      = $SQLDataPath
            SQLUserDBDir           = $SQLDataPath
            SQLUserDBLogDir        = $SQLLogsPath
            SQLTempDBDir           = $SQLDataPath
            SQLTempDBLogDir        = $SQLLogsPath
            SQLBackupDir           = $SQLDataPath
            SourcePath             = $SQLPath
            UpdateEnabled          = 'True'
            ForceReboot            = $false
            SqlTempdbFileCount     = 4
            SqlTempdbFileSize      = 1024
            SqlTempdbFileGrowth    = 512
            SqlTempdbLogFileSize   = 128
            SqlTempdbLogFileGrowth = 64
            SecurityMode           = 'SQL'
            TcpEnabled             = $true
            NpEnabled              = $false
            BrowserSvcStartupType  = 'Disabled'
            SAPwd                  = $SACredential
            DependsOn              = @("[File]SQLData","[File]SQLLogs", "[File]SQLLocalInstall","[SS911_Common]Servers")

        } 

        SqlConfiguration AllowUpdates
        {
            InstanceName    = 'MSSQLSERVER' 
            OptionName      = 'Allow Updates'
            OptionValue     = 1
        }

        SqlAgentOperator Operators
        {
            Ensure          = 'Present'
            Name            = 'DBA'
            InstanceName    = 'MSSQLSERVER'
            EmailAddress    = 'david.reinker@southsound911.org;nelson.eng@southsound911.org'
        }

        SqlConfiguration EnableDatabaseMailXPs
        {
            InstanceName    = 'MSSQLSERVER'
            OptionName      = 'Database Mail XPs'
            OptionValue     = 1
            RestartService  = $false
        }

        cChocoPackageInstaller SSMS 
        {
            DependsOn="[SqlSetup]InstallSQL"
            Name="sql-server-management-studio"
            Ensure="Present"
        }

        # End SQLSetup

    } # End Node
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

LCMConfig -ConfigurationData DMZNodes.psd1

# Hard-coded source location for modules and other files to copy to target server
$Source = "\\netops08.ss911.net\temp"

# Get credentials.  Credentials for David have been placed in the creds folder.  This is a convenience to avoid
# entering credentials every time it's run
if ($null -eq $SQLServiceCredential) { $SQLServiceCredential = Import-Clixml -path $source\creds\$env:username\$env:computername\sqlservice.xml }
if ($null -eq $SACredential) { $SACredential = Import-Clixml -path $source\creds\$env:username\$env:computername\sa.xml }

# Create MOF files
DMZServers -Source $Source -ConfigurationData DMZNodes.psd1 -SqlServiceCredential $SQLServiceCredential -SACredential $SACredential 

