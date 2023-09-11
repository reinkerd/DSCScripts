param ([string[]]$Servers)

# Run this configuration like this: ./<this file>.ps1 -Servers <servernames> 
# Example: /SQL.ps1 -Servers labsql1.ss911.net 

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
        
        $SybasePath  = "C:\Sybase157"

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

# Get credentials
if ($null -eq $SQLServiceCredential) { $SQLServiceCredential = Import-Clixml -path $source\creds\sqlservice.xml }
if ($null -eq $SACredential) { $SACredential = Import-Clixml -path $source\creds\sa.xml }

# Create MOF files
SQLServers -Source $Source -ConfigurationData sqlnodes.psd1 -SqlServiceCredential $SQLServiceCredential -SACredential $SACredential 

# Copy these module files to the source folder from which files are copied to the server 
copy-item -path "c:\program files\windowspowershell\modules\ss911" -filter "*.*" -destination "$Source\Modules" -force -Recurse

foreach ($Server in $Servers)
{
    # Copy modules to target
    copy-item -path "$source\Modules" -filter "*.*" -Destination "\\$Server\c$\Program Files\WindowsPowerShell" -force -Recurse
    
    #Create cim session to pass to start-dscconfiguration
    $cim=New-CimSession -computername $Server

    Start-DscConfiguration -CimSession $cim -path ".\SQLServers\" -verbose -force -wait 

    if (test-path -path "$source\$Server\lockdown.sql") { Invoke-Sqlcmd -ServerInstance $Server -InputFile "$source\$Server\lockdown.sql" }

}

