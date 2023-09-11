$Server = "DevBuildSvr1.ss911.net"

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
            SQLPath="c:\sql2017"
            SQLDataPath="c:\sqldata"
            SQLLogsPath="c:\sqllogs"
            #Administrators='lesa\devbuild','lesa\lesa-it-developers','lesa\tfsbuild','lesa\tfsservice'
         }
     )
}

Configuration SQLServers
{

    [CmdletBinding()]
    param
    (

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


        $SQLPath     = $Node.SQLPath
        $SQLDataPath = $Node.SQLDataPath
        $SQLLogsPath = $Node.SQLLogsPath

        #
        # Set up TLS - HTTP protocols, encryption, hashes, and activate TLS 1.2 for Powershell
        #

        ss911_tls TLS 
        {
            Ensure="Present"
        }


        #
        # Remote Powershell administration
        #

        WindowsFeature RemoteServerAdministration
        {
            Name="rsat-ad-powershell"
            Ensure="Present"
            IncludeAllSubFeature=$true
        }

        
        # 
        # Chocolatey - Install 7Zip, NotepadPlusPlus and OctopusTentacle
        #

        cChocoInstaller installChoco
        {
            #DependsOn="[WindowsFeature]NetCore35"
            InstallDir="C:\ProgramData\chocolatey"   
        }

        cChocoPackageInstaller 7Zip
        {
            DependsOn="[cChocoInstaller]installChoco"
            Name="7Zip"
            Ensure="Present"
        }

        cChocoPackageInstaller NotePadPlusPlus
        {
            DependsOn="[cChocoInstaller]installChoco"
            Name="NotePadPlusPlus"
            Ensure="Present"
        }

        cChocoPackageInstaller OctopusTentacle
        {
            DependsOn="[cChocoInstaller]installChoco"
            Name="octopusdeploy.tentacle"
            Ensure="Present"
            Version="6.0.489"
            Chocoparams="--allow-empty-checksums"
        }


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

        File SQL2017 
        {
            DestinationPath=$SQLPath
            Type="Directory"
            SourcePath="$source\SQL2017"
            Ensure="Present"
            Recurse=$true
        }


        #
        # Install IIS so we can do a web redirect
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
        
        xWebSite OctopusDeployRedirect
        {
            Ensure="Present"
            Name="OctopusDeployRedirect"
            DependsOn="[WindowsFeature]WebServer"
            State="Started"
            PhysicalPath="c:\inetpub\wwwroot"
            BindingInfo=@(
                @(MSFT_xWebBindingInformation
                {
                    Protocol="HTTP"
                    Port="80"
                    IPAddress="*"
                    HostName="Octopus.SouthSound911.org"
                }
                );
                @(MSFT_xWebBindingInformation
                {
                    Protocol="HTTP"
                    Port="80"
                    IPAddress="*"
                    HostName="Octopus"
                }
                )
            )
            AuthenticationInfo=MSFT_xWebAuthenticationInformation 
            {
                # Allow only anonymous authentication
                Anonymous=$true
                Windows=$false
            }
        }
        

        #
        # Install SQL Server
        #

        SqlSetup InstallSQL
        {
            InstanceName           = 'MSSQLSERVER'
            Action                 = 'Install'
            Features               = 'SQLENGINE,CONN'
            SQLCollation           = 'SQL_Latin1_General_CP1_CI_AS'
            # SQLSvcAccount        = $SqlServiceCredential  # Use default value
            SQLSvcStartupType      = 'Automatic'
            # AgtSvcAccount        = $SqlServiceCredential  # Use default value
            AgtSvcStartupType      = 'Automatic'
            SQLSysAdminAccounts    = @('LESA\ReinkerD','LESA\Engn')
            InstallSharedDir       = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir    = 'C:\Program Files (x86)\Microsoft SQL Server'
            InstanceDir            = 'C:\Program Files\Microsoft SQL Server'
            SQMReporting           = 'False'
            InstallSQLDataDir      = $SQLDataPath
            SQLUserDBDir           = $SQLDataPath
            SQLUserDBLogDir        = $SQLLogsPath
            SQLTempDBDir           = $SQLDataPath
            SQLTempDBLogDir        = $SQLLogsPath
            SQLBackupDir           = $SQLDataPath
            SourcePath             = "$Source\SQL2017"
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
            BrowserSvcStartupType  = 'Manual'
            SAPwd                  = $SACredential
            DependsOn              = @("[File]SQLData","[File]SQLLogs", "[File]SQL2017")

        } # End SQLSetup


        #                                                                                                                 
        # Install SSMS
        #                                                                                                                 

        cChocoPackageInstaller SSMS
        {
            Name="sql-server-management-studio"
            Ensure="Present"
            DependsOn="[SqlSetup]InstallSQL"
        }

        #
        # Local Administrators
        #
        
        <#
        Group LocalAdministrators
        {
            Ensure="Present"
            GroupName="Administrators"
            MembersToInclude=$Node.Administrators
        }
        #>

    } #End Node
}

# Hard-coded source location for modules and other files to copy to target server
$Source = "\\itdev46.lesa.net\temp"

# Get credentials
# We're using default value of NT Service for the SQL service account credentials, so just need the SA credentials
if ($null -eq $SACredential) { $SACredential = Import-Clixml -path $source\creds\sa.xml }

# Create MOF files
SQLServers -Source $Source -ConfigurationData $Nodes -SACredential $SACredential 

# Copy these module files to the source folder from which files are copied to the server 
copy-item -path "c:\program files\windowspowershell\modules\ss911" -filter "*.*" -destination "$Source\Modules" -force -Recurse

# Copy modules to target
copy-item -path "$source\Modules" -filter "*.*" -Destination "\\$Server\c$\Program Files\WindowsPowerShell" -force -Recurse
    
#Create cim session to pass to start-dscconfiguration
$cim=New-CimSession -computername $Server

Start-DscConfiguration -CimSession $cim -path ".\SQLServers\" -verbose -force -wait

#
# Configure HTTP Redirect
#

Invoke-Command -ComputerName $Server -ScriptBlock {
    set-webconfiguration system.webServer/httpRedirect "IIS:\Sites\OctopusDeployRedirect" -Value @{enabled="true";destination="http://$($Server):8082";exactDestination="true";httpResponseStat="Found";childOnly="true"}
}

#
# Run SQL Lockdown script, if present
#

if (test-path -path "$source\$Server\lockdown.sql") { Invoke-Sqlcmd -ServerInstance $Server -InputFile "$source\$Server\lockdown.sql" }


