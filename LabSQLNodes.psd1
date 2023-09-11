@{
    AllNodes = @(
        @{ 
            NodeName="*" 
            psdscallowplaintextpassword = $true
            PSDscAllowDomainUser=$true
        },
         @{
            NodeName="LabSQL2.ss911.net" 
            SQLPath="c:\sql2019"
            SQLDataPath="c:\sqldata"
            SQLLogsPath="c:\sqllogs"
            Environment="D"
         },
         @{
            NodeName="LabSQL3.ss911.net" 
            SQLPath="c:\sql2019"
            SQLDataPath="c:\sqldata"
            SQLLogsPath="c:\sqllogs"
            Environment="D"
         }
     )
}