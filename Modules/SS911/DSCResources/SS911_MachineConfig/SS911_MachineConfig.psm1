function Modify-MachineConfig
{ 

    param($machineconfigpath, $Environment)

    $saveit = $false

    [xml]$machineconfig = get-content $machineconfigpath

    switch ($Environment)
    {
        "Development" { $AgencyPath = "C:\LESA-Development\Data\Config\AgencyInformation.config" }
        "QualityAssurance" { $AgencyPath = "C:\LESA-QualityAssurance\Data\Config\AgencyInformation.config" }
        "Production" { $AgencyPath = "C:\LESA\Data\Config\AgencyInformation.config" }
        "Training" { $AgencyPath = "C:\LESA-Training\Data\Config\AgencyInformation.config" }
    }

    $node = $machineconfig.selectsinglenode("/configuration/configSections/section/@name[. = 'LESASystems']") 
    if ($node.value -ne 'LESASystems') {
	    #Add Node
        $tempxmldoc = new-object system.xml.xmldocument
	    $tempxmldoc.loadxml("<section name='LESASystems' type='System.Configuration.NameValueFileSectionHandler, System, Version=1.0.5000.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'/>")
	    $newnode = $machineconfig.importnode($tempxmldoc.documentelement, $true)
	    $machineconfig.configuration.configSections.appendchild($newnode)
        $saveit = $true
    }

    $node = $machineconfig.selectsinglenode("/configuration/LESASystems") 
    if ($node.name -ne 'LESASystems') {
	    #Add Node
        $tempxmldoc = new-object system.xml.xmldocument
	    $tempxmldoc.loadxml("<LESASystems file='c:\Program files\lesa\config\LESASystems.config' />")
	    $newnode = $machineconfig.importnode($tempxmldoc.documentelement, $true)
	    $machineconfig.configuration.appendchild($newnode)
        $saveit = $true
    }

    $node = $machineconfig.selectsinglenode("/configuration/appSettings") 
    if ($node -eq $null) {
	    #Add Node
        $tempxmldoc = new-object system.xml.xmldocument
	    $tempxmldoc.loadxml("<appSettings file='$AgencyPath'><add key='SystemModeFilename' value='c:\program files\lesa\lesadata\mode.txt' /><add key='SystemConnectionsFilename' value='c:\program files\lesa\LesaData\Connections.txt' /><add key='Development-LesaRootFolder' value='c:\LESA-Development\'></add><add key='Production-LesaRootFolder' value='c:\LESA\'></add><add key='QualityAssurance-LesaRootFolder' value='c:\LESA-QualityAssurance\'></add><add key='Staging-LesaRootFolder' value='c:\LESA-Staging\'></add><add key='Training-LesaRootFolder' value='c:\LESA-Training\'></add></appSettings>")
	    $newnode = $machineconfig.importnode($tempxmldoc.documentelement, $true)
	    $machineconfig.configuration.appendchild($newnode)
        $saveit = $true
    }

    if ($saveit) {
        $backupfilename = $machineconfigpath + ".bak"
        $count = 0
        while (test-path $backupfilename) {
            $count=$count+1
            $backupfilename = $backupfilename + $count
        }
        copy-item $machineconfigpath $backupfilename
        $machineconfig.save($machineconfigpath)
    }

}


function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [ValidateSet("Development","QualityAssurance","Production","Training")]
        [System.String]
        $Environment
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."


    $returnValue = @{
        Ensure = [System.String]$Ensure
        Environment = [System.String]$Environment
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [ValidateSet("Development","QualityAssurance","Production","Training")]
        [System.String]
        $Environment
    )

    #Include this line if the resource requires a system reboot.
    #$global:DSCMachineStatus = 1

    if ($Ensure -eq "Present")
    {
        write-verbose "Modifying Machine config files for SS911 applications"
        Modify-MachineConfig -Environment $Environment -MachineConfigPath "C:\Windows\Microsoft.NET\Framework\v2.0.50727\CONFIG\machine.config"
        Modify-MachineConfig -Environment $Environment -MachineConfigPath "C:\Windows\Microsoft.NET\Framework\v4.0.30319\Config\machine.config"
        Modify-MachineConfig -Environment $Environment -MachineConfigPath "C:\Windows\Microsoft.NET\Framework64\v2.0.50727\CONFIG\machine.config"
        Modify-MachineConfig -Environment $Environment -MachineConfigPath "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\Config\machine.config"
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [ValidateSet("Development","QualityAssurance","Production","Training")]
        [System.String]
        $Environment
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."


    $result = [System.Boolean]$false
    
    $result
    #>
}


Export-ModuleMember -Function *-TargetResource

