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
            NodeName='RMSReports.ss911.net' 
            SQLPath="e:\Installs\sql2022"
            SSRSPath = 'e:\installs\ssrs2019'
            SQLDataPath="e:\sqldata"
            SQLLogsPath="e:\sqllogs"
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

        ###################################################################################################################
        #                                                                                                                 
        # File Folders                                                                                                    
        #                                                                                                                 

        File SQLData
        {
            DestinationPath=$Node.SQLDataPath
            Ensure="Present"
            Type="Directory"
        }

        File SQLLogs
        {
            DestinationPath=$Node.SQLLogsPath
            Ensure="Present"
            Type="Directory"
        }



        ###################################################################################################################
        #                                                                                                                 
        # SQL Server                                                                                                      
        #                                                                                                                 

        SqlSetup InstallSQL
        {
            InstanceName           = 'MSSQLSERVER'
            Action                 = 'Install'
            Features               = 'SQLENGINE'
            SQLCollation           = 'SQL_Latin1_General_CP1_CI_AS'
            SQLSvcAccount          = $SqlServiceCredential
            SQLSvcStartupType      = 'Automatic'
            AgtSvcAccount          = $SqlServiceCredential
            AgtSvcStartupType      = 'Automatic'
            SQLSysAdminAccounts    = @('SS911\ReinkerD','SS911\EngN')
            SQMReporting           = 'False'
            IsSvcStartupType       = 'Automatic'
            InstallSQLDataDir      = $Node.SQLDataPath
            SQLUserDBDir           = $Node.SQLDataPath
            SQLUserDBLogDir        = $Node.SQLLogsPath
            SQLTempDBDir           = $Node.SQLDataPath
            SQLTempDBLogDir        = $Node.SQLLogsPath
            SQLBackupDir           = $Node.SQLDataPath
            SourcePath             = $Node.SQLPath
            UpdateEnabled          = 'True'
            ForceReboot            = $false
            SqlTempdbFileCount     = 1
            SqlTempdbFileSize      = 1024
            SqlTempdbFileGrowth    = 512
            SqlTempdbLogFileSize   = 128
            SqlTempdbLogFileGrowth = 64
            SecurityMode           = 'SQL'
            TcpEnabled             = $true
            NpEnabled              = $false
            BrowserSvcStartupType  = 'Manual'
            SAPwd                  = $SACredential
            DependsOn              = @("[File]SQLData","[File]SQLLogs", "[File]SQL2022")

            #PsDscRunAsCredential = $SqlInstallCredential

        } # End SQLSetup


        SqlRSSetup SSRS
        {
            InstanceName = 'SSRS'
            IAcceptLicenseTerms = 'Yes'
            SourcePath = $Node.SSRSPath
            Action = 'Install'
            DependsOn = '[SqlSetup]InstallSQL'
        }


        SqlRS SSRSConfiguration
        {
            InstanceName = 'MSSQLSERVER'
            DatabaseServerName = 'localhost'
            DatabaseInstanceName = 'MSSQLSERVER'
            DependsOn = '[SqlRSSetup]SSRS'
        }


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
if ($null -eq $SQLServiceCredential) { $SQLServiceCredential = Import-Clixml -path $source\creds\sqlservice.xml }
if ($null -eq $SACredential) { $SACredential = Import-Clixml -path $source\creds\sa.xml }

# Create MOF files
SQLServers -Source $Source -ConfigurationData $Nodes -SqlServiceCredential $SQLServiceCredential -SACredential $SACredential 

