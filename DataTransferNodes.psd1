@{
    AllNodes = @(
        @{ 
            NodeName="*" 
            psdscallowplaintextpassword = $true
            PSDscAllowDomainUser=$true
        },
        @{
            NodeName="datatransfer.ss911.net"
            Environment="P"
            Administrators="LESA\Dev leads","LESA\ChanK","LESA\Eng","LESA\ESOCADMonitor","LESA\jindex","LESA\LesaUtilities","LESA\McNamarM,LESA\FossB"
            IPAddress="192.103.180.56"
        },
        @{
            NodeName="devdatatransfer.ss911.net"
            Environment="D"
            Administrators="LESA\lesa-it-developers","LESA\LesaUtilities","LESA\WarrantsAttachments"
            IPAddress="192.103.188.185"
        },
        @{
            NodeName="qadatatransfer.ss911.net"
            Environment="Q"
            Administrators="LESA\lesa-it-developers","LESA\LesaUtilities","LESA\WarrantsAttachments"
        }
     )
}