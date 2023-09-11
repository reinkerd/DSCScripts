
$DSCResourceName="SS911_MachineConfig"

# Get the Resource designer
import-module -name xdscresourcedesigner 

# One-time only commands to create the new Module and DSC Resource
$Ensure = New-xDscResourceProperty -Name Ensure -Type String -Attribute Key -ValidateSet "Present", "Absent"
$Environment = New-xDscResourceProperty -Name Environment -Type String -Attribute Required -ValidateSet "Development", "QualityAssurance", "Production", "Training"

# This command creates one or more folders, and creates the .psm1 file boilerplate including get-resource, set-resource, etc., to be filled in by developer
# New-xDscResource -name $DSCResourceName -Property $Ensure -path 'c:\program files\windowspowershell\modules' -ModuleName SS911

# Test-xDscSchema -path "c:\program files\windowspowershell\modules\SS911\dscresources\$DSCResourceName\$DSCResourceName.schema.mof"

Update-xDscResource -name $DSCResourceName -Property  $Ensure, $Environment -force

# All parameters must be marked with either Key, Required, Write or Read property

Test-xDscSchema -path "c:\program files\windowspowershell\modules\SS911\dscresources\$DSCResourceName\$DSCResourceName.schema.mof"
