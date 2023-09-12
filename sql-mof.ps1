
# Run this configuration like this: ./<this file>.ps1 
# Example: /sql-mof.ps1 

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

        SS911_Common Servers       
        {
            Source=$Source
            Node=$Node
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
            SourcePath="$source\SQL2022"
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
            BrowserSvcStartupType  = 'Manual'
            SAPwd                  = $SACredential
            DependsOn              = @("[File]SQLData","[File]SQLLogs", "[File]SQLLocalInstall","[SS911_Common]Servers")

        } # End SQLSetup

    } # End Node
}

# Hard-coded source location for modules and other files to copy to target server
$Source = "\\itdev46.lesa.net\temp"

# Get credentials.  Credentials for David have been placed in the creds folder.  This is a convenience to avoid
# entering credentials every time it's run
if ($null -eq $SQLServiceCredential) { $SQLServiceCredential = Import-Clixml -path $source\creds\sqlservice.xml }
if ($null -eq $SACredential) { $SACredential = Import-Clixml -path $source\creds\sa.xml }

# Create MOF files
SQLServers -Source $Source -ConfigurationData sqlnodes.psd1 -SqlServiceCredential $SQLServiceCredential -SACredential $SACredential 

