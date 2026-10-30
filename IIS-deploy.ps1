
param ([string]$Server)

# Hard-coded source location for modules and other files to copy to target server
$source = "\\netops08.ss911.net\temp"

copy-item -path "c:\program files\windowspowershell\modules\ss911" -filter "*.*" -destination "$Source\Modules" -force -Recurse

# Copy modules to target
copy-item -path "$source\Modules" -filter "*.*" -Destination "\\$Server\c$\Program Files\WindowsPowerShell" -force -Recurse
    
Start-DscConfiguration -ComputerName $Server -path ".\IISServers\" -verbose -force -wait

Set-DscLocalConfigurationManager -computername $Server -path ".\lcmconfig\"

$cim=New-CimSession -computername $Server

remove-odbcdsn -CimSession $cim -name 'DataWarehouse' -DsnType System -Platform '32-bit' 
remove-odbcdsn -CimSession $cim -name 'DataWarehouse' -DsnType System -Platform '64-bit' 

remove-odbcdsn -CimSession $cim -name 'SQL-Warehouse' -DsnType System -Platform '32-bit' 
remove-odbcdsn -CimSession $cim -name 'SQL-Wwarehouse' -DsnType System -Platform '64-bit' 

remove-odbcdsn -CimSession $cim -name 'SQL-Main' -DsnType System -Platform '32-bit' 
remove-odbcdsn -CimSession $cim -name 'SQL-Main' -DsnType System -Platform '64-bit' 

remove-odbcdsn -CimSession $cim -name 'linxsyb' -DsnType System -Platform '32-bit' 
remove-odbcdsn -CimSession $cim -name 'linxsyb' -DsnType System -Platform '64-bit' 

if ($server -like "dev*") {
    Add-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit -SetPropertyValue @("Server=sql-dev.ss911.net", "Database=LESA_Case", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit -SetPropertyValue @("Server=sql-dev.ss911.net", "Database=LESA_Case", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit -SetPropertyValue @("Server=sql-dev.ss911.net", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit -SetPropertyValue @("Server=sql-dev.ss911.net", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name SQL-Main-new -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name SQL-Main-new -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit -SetPropertyValue @("Server=sql-dev.ss911.net", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name SQL-Main -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name SQL-Main -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit -SetPropertyValue @("Server=sql-dev.ss911.net", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name SQL-Main -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name SQL-Main -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit -SetPropertyValue @("Server=sql-dev.ss911.net", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name linxsyb -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name linxsyb -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 64-bit -SetPropertyValue @("userid=lesa_prod", "clienthostname=$Server.ss911", "port=4000", "database=linx", "server=linxstaging.co.pierce.wa.us")

    Add-OdbcDsn -CimSession $cim -name linxsyb -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name linxsyb -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 32-bit -SetPropertyValue @("userid=lesa_prod", "clienthostname=$Server.ss911", "port=4000", "database=linx", "server=linxstaging.co.pierce.wa.us")

} elseif ($server -like "test*" -or $Server -like "qa*") {

    Add-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit -SetPropertyValue @("Server=sql-qa.ss911.net", "Database=LESA_Case", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit -SetPropertyValue @("Server=sql-qa.ss911.net", "Database=LESA_Case", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit -SetPropertyValue @("Server=sql-qa.ss911.net", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit -SetPropertyValue @("Server=sql-qa.ss911.net", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name SQL-Main -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name SQL-Main -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit -SetPropertyValue @("Server=sql-qa.ss911.net", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name SQL-Main -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name SQL-Main -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit -SetPropertyValue @("Server=sql-qa.ss911.net", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name linxsyb -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name linxsyb -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 64-bit -SetPropertyValue @("userid=lesa_prod", "clienthostname=sqltransfer01.ss911", "port=4000", "database=linx", "server=linxstaging.co.pierce.wa.us")

    Add-OdbcDsn -CimSession $cim -name linxsyb -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name linxsyb -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 32-bit -SetPropertyValue @("userid=lesa_prod", "clienthostname=sqltransfer01.ss911", "port=4000", "database=linx", "server=linxstaging.co.pierce.wa.us")

}

else {

    Add-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit -SetPropertyValue @("Server=sql-warehouse.lesa.net", "Database=LESA_Case", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name DataWarehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit -SetPropertyValue @("Server=sql-warehouse.lesa.net", "Database=LESA_Case", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit -SetPropertyValue @("Server=sql-warehouse.lesa.net", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name SQL-warehouse -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit -SetPropertyValue @("Server=sql-warehouse.lesa.net", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name SQL-Main -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name SQL-Main -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 64-bit -SetPropertyValue @("Server=sql-main.lesa.net", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name SQL-Main -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name SQL-Main -DriverName "ODBC Driver 18 for SQL Server" -dsntype System -Platform 32-bit -SetPropertyValue @("Server=sql-main.lesa.net", "TrustServerCertificate=No") 

    Add-OdbcDsn -CimSession $cim -name linxsyb -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 64-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name linxsyb -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 64-bit -SetPropertyValue @("userid=lesa_prod", "clienthostname=sqltransfer01.ss911", "port=1031", "database=linx", "server=linx.co.pierce.wa.us")

    Add-OdbcDsn -CimSession $cim -name linxsyb -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 32-bit  -ErrorAction SilentlyContinue
    Set-OdbcDsn -CimSession $cim -name linxsyb -DriverName "Adaptive Server Enterprise" -dsntype System -Platform 32-bit -SetPropertyValue @("userid=lesa_prod", "clienthostname=sqltransfer01.ss911", "port=1031", "database=linx", "server=linx.co.pierce.wa.us")

}



# Also - register the COM+ applications
