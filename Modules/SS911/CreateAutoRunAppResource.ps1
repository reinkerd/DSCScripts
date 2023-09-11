
$DSCResourceName="ss911_AutoRunApp"

# Get the Resource designer
install-module -name xdscresourcedesigner

# One-time only commands to create the new Module and DSC Resource
# All parameters must be marked with either Key, Required, Write or Read property
$Ensure = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet "Present", "Absent"
$Application = New-xDscResourceProperty -Name Application -Type String -Attribute Key
$Login = New-xDscResourceProperty -Name Login -Type String -Attribute Write 
$Path = New-xDscResourceProperty -Name Path -Type String -Attribute Write 

# This command creates one or more folders, and creates the .psm1 file boilerplate including get-resource, set-resource, etc., to be filled in by developer
New-xDscResource -name $DSCResourceName -Property $Ensure, $Application, $Login, $Path -path "c:\program files\windowspowershell\modules" -ModuleName SS911 -Force

#Update-xDscResource -name $DSCResourceName -Property $Ensure, $ADGroup, $MembersToInclude -force

Test-xDscSchema -path "c:\program files\windowspowershell\modules\SS911\dscresources\$DSCResourceName\$DSCResourceName.schema.mof"

