@{
    AllNodes = @(
        @{ 
            NodeName="*" 
            psdscallowplaintextpassword = $true
            PSDscAllowDomainUser=$true
        },
         @{
            NodeName="WarrantTransfer01.ss911.net" 
            Environment="P"
         }
     )
}