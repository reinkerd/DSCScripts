@{
    AllNodes = @(
        @{ 
            NodeName="*" 
            psdscallowplaintextpassword = $true
            PSDscAllowDomainUser=$true
        },
         @{
            NodeName="DevIIS4.ss911.net" 
            SQLPath="c:\sql2025"
            SQLDataPath="c:\sqldata"
            SQLLogsPath="c:\sqllogs"
            Environment="D"
         }
    )
}