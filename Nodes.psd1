@{
    AllNodes = @(
        @{ 
            NodeName="*" 
            psdscallowplaintextpassword = $true
            PSDscAllowDomainUser=$true
        },
        @{ 
            NodeName="LabSQL1.ss911.net" 
            Role="IISServer"
            IPAddress="192.103.188.140"
            RunDVOUpload=$true
            Environment="D"
         },
         @{
            NodeName="PDFBuild.ss911.net" 
            Environment="P"
         }
    )
}