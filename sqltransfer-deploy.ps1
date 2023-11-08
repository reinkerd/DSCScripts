param ([string]$Server)

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

$source = '\\netops08.ss911.net\Temp'

# Copy these module files to the source folder from which files are copied to the server 
copy-item -path "c:\program files\windowspowershell\modules\ss911" -filter "*.*" -destination "$Source\Modules" -force -Recurse

# Copy modules to target
copy-item -path "$source\Modules" -filter "*.*" -Destination "\\$Server\c$\Program Files\WindowsPowerShell" -force -Recurse

# Create cim session to pass to start-dscconfiguration
$cim=New-CimSession -computername $Server

# Configure server
Start-DscConfiguration -CimSession $cim -Path ".\SQLServers\" -Verbose -Wait -Force

New-ODBCDSNs -cim $cim

Invoke-Sqlcmd -ServerInstance $Server -InputFile "$source\$Server\lockdown.sql" 


