

function Set-RunAsAdministrator
{
    param([string]$Path)

    New-item -path "REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Force -ErrorAction SilentlyContinue
    New-ItemProperty -path "REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Name $Path -value 'RUNASADMIN' -Force -ErrorAction SilentlyContinue

}

function Set-Shortcut 
{
    param ([string]$SourceExe, [string]$ArgumentsToSourceExe, [string]$DestinationPath)

    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($DestinationPath)
    $Shortcut.TargetPath = $SourceExe
    $Shortcut.Arguments = $ArgumentsToSourceExe
    $Shortcut.Save()
}


function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Application
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."


    
    $returnValue = @{
    Ensure = $Ensure
    Application = $Application
    Login = $Login
    Path = $Path
    }

    $returnValue
    
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Application,

        [System.String]
        $Login,

        [System.String]
        $Path
    )
    
    $username = $Login

    if ($username -match "(\w+)\\(\w+)")
    {

        $domain = $matches[1]
        $account = $matches[2]

        $fullpath = join-path $path $Application

        set-shortcut -SourceExe $fullpath -DestinationPath "C:\Users\$account\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\StateInterface.lnk" 
        Set-RunAsAdministrator -path $fullpath

    }

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    #Include this line if the resource requires a system reboot.
    #$global:DSCMachineStatus = 1

}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Application,

        [System.String]
        $Login,

        [System.String]
        $Path
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."
    
    $username = $Login

    $result = $false

    if ($username -match "(\w+)\\(\w+)")
    {
        $domain = $matches[1]
        $account = $matches[2]

        $result = test-path -path "C:\Users\$account\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\StateInterface.lnk" -ErrorAction SilentlyContinue

    }
    
    $result
}


Export-ModuleMember -Function *-TargetResource

