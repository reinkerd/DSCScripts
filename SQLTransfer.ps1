###############################################################################################################
#
# Run this configuration like this
# Change directory to app folder Ex: c:\workingfoldertfs\servers\buildscripts
# Run in powershell: ./<this file>.ps1 - Example: ./SQLTransfer.ps1  
# 

# Hard-coded source location for modules and other files to copy to target server
$Source = "\\nas01.lesa.net\staff\IT\NETWORK\Powershell\DSCServerSource"
$Server = "SQLTransfer01.ss911.net"

$Nodes = @{
    AllNodes = @(
        @{ 
            NodeName="*" 
            psdscallowplaintextpassword = $true
            PSDscAllowDomainUser=$true
        },
         @{
            NodeName=$Server 
            SQLPath="c:\sql2019"
            SQLDataPath="c:\sqldata"
            SQLLogsPath="c:\sqllogs"
            Environment="P"
            Administrators="LESA\CaseImages","LESA\Deployers","LESA\Domain Admins","LESA\LESA_SQL","LESA\LESAUtilities","SS911\SQLService"
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

    Import-DscResource -ModuleName PSDesiredStateConfiguration, cchoco, ss911, SQLServerDSC 


    Node $AllNodes.NodeName
    {

        $SQLPath     = $Node.SQLPath
        $SQLDataPath = $Node.SQLDataPath
        $SQLLogsPath = $Node.SQLLogsPath
        

        ###################################################################################################################
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
        # Install MS Access 2016 Runtime
        #                                                                                                                 

        cChocoPackageInstaller MSAccess
        {
            DependsOn="[SS911_Common]Servers"
            Name="access2016runtime"
            Ensure="Present"
        }


        ###################################################################################################################
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

        if (test-path -path "$Source\$($Node.NodeName)\Scripts") {
            File Scripts
            {
                DestinationPath="C:\Scripts"
                Ensure="Present"
                Type="Directory"
                SourcePath="$Source\$($Node.NodeName)\Scripts"
                Recurse=$true
            }
        }

        File LORS
        {
            DestinationPath="C:\LORS"
            Ensure="Present"
            Type="Directory"
            SourcePath="$Source\$($Node.NodeName)\LORS"
            Recurse=$true
        }

        File bookingrostertransfer
        {
            DestinationPath="C:\bookingrostertransfer"
            Ensure="Present"
            Type="Directory"
            SourcePath="$Source\$($Node.NodeName)\bookingrostertransfer"
            Recurse=$true
        }

        File SQL2019 
        {
            DestinationPath=$SQLPath
            Type="Directory"
            SourcePath="$Source\SQL2019"
            Ensure="Present"
            Recurse=$true
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
        # SQL Server                                                                                                      
        #                                                                                                                 

        SqlSetup InstallSQL
        {
            InstanceName           = 'MSSQLSERVER'
            Action                 = 'Install'
            Features               = 'SQLENGINE,REPLICATION,FULLTEXT,CONN,IS'
            SQLCollation           = 'SQL_Latin1_General_CP1_CI_AS'
            SQLSvcAccount          = $SqlServiceCredential
            SQLSvcStartupType      = 'Automatic'
            AgtSvcAccount          = $SqlServiceCredential
            AgtSvcStartupType      = 'Automatic'
            SQLSysAdminAccounts    = @('LESA\ReinkerD','LESA\Engn')
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
            SourcePath             = "$Source\SQL2019"
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
            DependsOn              = @("[File]SQLData","[File]SQLLogs", "[File]SQL2019","[SS911_Common]Servers")

            #PsDscRunAsCredential = $SqlInstallCredential

        } # End SQLSetup


        ###################################################################################################################
        #                                                                                                                 
        # Install SSMS
        #                                                                                                                 

        cChocoPackageInstaller SSMS
        {
            Name="sql-server-management-studio"
            Ensure="Present"
            DependsOn="[SqlSetup]InstallSQL"
        }



    } #End Node
}

function New-ODBCDSNs {

    param ([cimsession]$cim)

    Add-OdbcDsn -CimSession $cim -name BookingReport -DriverName "SQL Server" -dsntype System -Platform 32-bit -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name BookingReport -DriverName "SQL Server" -dsntype System -Platform 32-bit -SetPropertyValue @("Server=localhost", "Database=JMSDataXfer") 

    Add-OdbcDsn -CimSession $cim -name Netmenu -DriverName "SQL Server" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name Netmenu -DriverName "SQL Server" -dsntype System -Platform 32-bit -SetPropertyValue @("Server=sql-warehouse.lesa.net", "Database=LESA_Case") 

    Add-OdbcDsn -CimSession $cim -name judi -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name judi -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 32-bit -SetPropertyValue @("userid=lesa_prod", "clienthostname=sqltransfer01.ss911", "port=1031", "database=judi", "server=linx.co.pierce.wa.us")

    Add-OdbcDsn -CimSession $cim -name linxsrv -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name linxsrv -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 32-bit -SetPropertyValue @("userid=lesa_prod", "clienthostname=sqltransfer01.ss911", "port=1031", "database=linx", "server=linx.co.pierce.wa.us")

    Add-OdbcDsn -CimSession $cim -name linxsyb -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name linxsyb -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 64-bit -SetPropertyValue @("userid=lesa_prod", "clienthostname=sqltransfer01.ss911", "port=1031", "database=linx", "server=linx.co.pierce.wa.us")

    Add-OdbcDsn -CimSession $cim -name linxsyb2 -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 64-bit -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name linxsyb2 -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 64-bit -SetPropertyValue @("userid=lesa_prod", "clienthostname=sqltransfer01.ss911", "port=1031", "database=linx", "server=linx.co.pierce.wa.us")

    Add-OdbcDsn -CimSession $cim -name venus -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name venus -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 64-bit -SetPropertyValue @("userid=lesa_prod", "clienthostname=sqltransfer01.ss911", "port=2025", "database=linx", "server=venus.co.pierce.wa.us")

}


# Get stored credentials
if ($null -eq $SQLServiceCredential) { $SQLServiceCredential = Import-Clixml -path $source\creds\sqlservice.xml }
if ($null -eq $SACredential) { $SACredential = Import-Clixml -path $source\creds\sa.xml }

# Create MOF files
SQLServers -Source $Source -ConfigurationData $Nodes -SqlServiceCredential $SQLServiceCredential -SACredential $SACredential 

# Copy these module files to the source folder from which files are copied to the server 
copy-item -path "c:\program files\windowspowershell\modules\ss911" -filter "*.*" -destination "$Source\Modules" -force -Recurse

# if ($null -eq $Credential) { $Credential = Get-Credential -Message "Credentials for DSC to remotely connect" -UserName "$env:userdomain\$env:username" }

# Copy modules to target
copy-item -path "$source\Modules" -filter "*.*" -Destination "\\$Server\c$\Program Files\WindowsPowerShell" -force -Recurse

# Create cim session to pass to start-dscconfiguration
$cim=New-CimSession -computername $Server

# Configure server
Start-DscConfiguration -CimSession $cim -Path ".\SQLServers\" -Verbose -Wait -Force

New-ODBCDSNs -cim $cim

Invoke-Sqlcmd -ServerInstance $Server -InputFile "$source\$Server\lockdown.sql" 

# Deploy applications to server like CAD Data Transfer, etc.  
