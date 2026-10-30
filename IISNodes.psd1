@{
    AllNodes = @(
        @{ 
            NodeName="*" 
            psdscallowplaintextpassword = $true
            PSDscAllowDomainUser=$true
        },
        @{
            NodeName="DevIIS1-2025.ss911.net" 
            IPAddress="192.103.188.136"
            Websites="Netmenu","RMS","StateInterface","Records", "WebRMS","REDIRECT", "WebRMSRedirect"
            CertificateThumbprint = "cbf5f159fc6c3bae9274d80f1ba8e8bfa07f28ed"
            Environment="D"
        },
        @{
            NodeName="TestIIS1-2025.ss911.net" 
            IPAddress="192.103.188.134"
            Websites="Netmenu","RMS","StateInterface","Records", "WebRMS","REDIRECT", "WebRMSRedirect"
            CertificateThumbprint = "cbf5f159fc6c3bae9274d80f1ba8e8bfa07f28ed"
            Environment="Q"
        },
        @{
            NodeName="ProdIIS1-2025.ss911.net" 
            IPAddress="192.103.180.87"
            Websites="Netmenu","RMS","StateInterface","Records", "WebRMS","REDIRECT", "WebRMSRedirect"
            CertificateThumbprint = "cbf5f159fc6c3bae9274d80f1ba8e8bfa07f28ed"
            Environment="P"
        }
    )
}