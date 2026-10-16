
param ([string]$Server)

# Hard-coded source location for modules and other files to copy to target server
$source = "\\netops08.ss911.net\temp"

copy-item -path "c:\program files\windowspowershell\modules\ss911" -filter "*.*" -destination "$Source\Modules" -force -Recurse

# Copy modules to target
copy-item -path "$source\Modules" -filter "*.*" -Destination "\\$Server\c$\Program Files\WindowsPowerShell" -force -Recurse
    
Start-DscConfiguration -ComputerName $Server -path ".\IISServers\" -verbose -force -wait

Set-DscLocalConfigurationManager -computername $Server -path ".\lcmconfig\"

$cim=New-CimSession -computername $Server

Add-OdbcDsn -CimSession $cim -name linxsyb -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
Set-OdbcDsn -CimSession $cim -name linxsyb -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 64-bit -SetPropertyValue @("userid=lesa_prod", "clienthostname=sqltransfer01.ss911", "port=1031", "database=linx", "server=linx.co.pierce.wa.us")

Add-OdbcDsn -CimSession $cim -name linxsyb -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
Set-OdbcDsn -CimSession $cim -name linxsyb -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 32-bit -SetPropertyValue @("userid=lesa_prod", "clienthostname=sqltransfer01.ss911", "port=1031", "database=linx", "server=linx.co.pierce.wa.us")

if ($server -like "dev*") {
    Add-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit -SetPropertyValue @("Server=sql-warehouse.lesa.net", "Database=LESA_Case") 

    Add-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit -SetPropertyValue @("Server=sql-warehouse.lesa.net", "Database=LESA_Case") 

    Add-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit -SetPropertyValue @("Server=sql-warehouse.lesa.net") 

    Add-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit -SetPropertyValue @("Server=sql-warehouse.lesa.net") 

    Add-OdbcDsn -CimSession $cim -name SQL-Main-new -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name SQL-Main-new -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit -SetPropertyValue @("Server=sql-dev.lesa.net") 

}
else {
    Add-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "SQL Server" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "SQL Server" -dsntype System -Platform 64-bit -SetPropertyValue @("Server=sql-warehouse.lesa.net", "Database=LESA_Case") 

    Add-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "SQL Server" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "SQL Server" -dsntype System -Platform 32-bit -SetPropertyValue @("Server=sql-warehouse.lesa.net", "Database=LESA_Case") 

    Add-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "SQL Server" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "SQL Server" -dsntype System -Platform 64-bit -SetPropertyValue @("Server=sql-warehouse.lesa.net") 

    Add-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "SQL Server" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "SQL Server" -dsntype System -Platform 32-bit -SetPropertyValue @("Server=sql-warehouse.lesa.net") 

}

Add-OdbcDsn -CimSession $cim -name SQL-Main -DriverName "SQL Server" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
Set-OdbcDsn -CimSession $cim -name SQL-Main -DriverName "SQL Server" -dsntype System -Platform 64-bit -SetPropertyValue @("Server=sql-dev.lesa.net") 

Add-OdbcDsn -CimSession $cim -name SQL-Main -DriverName "SQL Server" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
Set-OdbcDsn -CimSession $cim -name SQL-Main -DriverName "SQL Server" -dsntype System -Platform 32-bit -SetPropertyValue @("Server=sql-dev.lesa.net") 
