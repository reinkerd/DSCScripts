@{
    AllNodes = @(
        @{ 
            NodeName="*" 
            psdscallowplaintextpassword = $true
            PSDscAllowDomainUser=$true
        },
        @{
            NodeName="DevIISFarm1.ss911.net" 
            IPAddress="192.103.188.245"
            Websites="Netmenu","RMS"
            Environment="D"
        }
    )
}
