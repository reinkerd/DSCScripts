@{
    AllNodes = @(
        @{ 
            NodeName="*" 
            psdscallowplaintextpassword = $true
            PSDscAllowDomainUser=$true
        },
         @{
            NodeName="FTPTransfer.ss911.net" 
            PDFFTP=$true
            LESAFTP=$true
            Environment="P"
         }
    )
}