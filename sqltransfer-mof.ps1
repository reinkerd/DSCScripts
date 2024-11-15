###############################################################################################################
#
# Run this configuration like this
# Change directory to app folder Ex: c:\workingfoldertfs\servers\buildscripts
# Run in powershell: ./<this file>.ps1 - Example: ./SQLTransfer.ps1  
# 


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
        
    ) # End Param


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
} # End Configuration


# Hard-coded source location for modules and other files to copy to target server
$Source = "\\netops08.ss911.net\temp"

# Get stored credentials
if ($null -eq $SQLServiceCredential) { $SQLServiceCredential = Import-Clixml -path $source\creds\$env:username\$env:computername\sqlservice.xml }
if ($null -eq $SACredential) { $SACredential = Import-Clixml -path $source\creds\$env:username\$env:computername\sa.xml }

# Create MOF files
SQLServers -Source $Source -ConfigurationData $Nodes -SqlServiceCredential $SQLServiceCredential -SACredential $SACredential 

