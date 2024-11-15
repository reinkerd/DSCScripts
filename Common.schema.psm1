
Configuration SS911_Common
{

    param (
        [string]$Source, # Path of files to be copied to the destination server
        [object]$Node
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration, cchoco, ss911 

    <#
    switch ($Node.Environment)
    {
        "D" { $Env = "Development" }
        "Q" { $Env = "QualityAssurance" }
        "P" { $Env = "Production" }
        "T" { $Env = "Training" }
    }
    #>

    #                                                                                                                 
    # Windows Features                                                                                                
    #                                                                                                                 

    WindowsFeature FileServer
    {
        Name = "FS-FileServer"
        Ensure = "Present"
    }

    WindowsFeature NetCore35
    {
        Name="NET-Framework-Core"
        Ensure="Present"
    }

    WindowsFeature RemoteServerAdministration
    {
        Name="rsat-ad-powershell"
        Ensure="Present"
        IncludeAllSubFeature=$true
    }


    #                                                                                                                 
    # Install Chocolatey and Chocolatey packages                                                                      
    #                                                                                                                 

    cChocoInstaller installChoco
    {
        DependsOn="[WindowsFeature]NetCore35"
        InstallDir="C:\ProgramData\chocolatey"   
    }

    cChocoPackageInstaller 7Zip
    {
        DependsOn="[cChocoInstaller]installChoco"
        Name="7Zip"
        Ensure="Present"
    }

    cChocoPackageInstaller NotePadPlusPlus
    {
        DependsOn="[cChocoInstaller]installChoco"
        Name="NotePadPlusPlus"
        Ensure="Present"
    }

    cChocoPackageInstaller OctopusTentacle
    {
        DependsOn="[cChocoInstaller]installChoco"
        Name="octopusdeploy.tentacle"
        Ensure="Present"
        Version="6.0.489"
        Chocoparams="--allow-empty-checksums"
    }

    cChocoPackageInstaller DotNet4
    {
        DependsOn="[cChocoInstaller]installChoco"
        Name="dotnetfx"
        Ensure="Present"
    }

    cChocoPackageInstaller DotNetCoreRuntime
    {
        DependsOn="[cChocoInstaller]installChoco"
        Name="dotnetcore-runtime"
        Ensure="Present"
    }


    cChocoPackageInstaller LogParser
    {
        DependsOn="[cChocoInstaller]installChoco"
        Name="logparser"
        Ensure="Present"
    }

    <#
    ss911_tls TLS 
    {
        Ensure="Present"
    }
    #>
    
    #
    # File Folders, shares and permissions
    #

    # All servers have a c:\lesa folder. However, the contents are different between production and non-production servers.
    switch -Regex ($Node.Environment)
    {
        "D|Q|T" {
            File LESARootFolder
            {
                DestinationPath="c:\LESA"
                SourcePath="$source\NonProdLESA"
                Type="Directory"
                Ensure="Present"
                Recurse = $true
            }
            File ProgramFilesLESA
            {
                DestinationPath="C:\Program Files\LESA"
                Type="Directory"
                SourcePath="$source\Program Files\NonProdLESA"
                Ensure="Present"
                Recurse=$true
            }
        }
        "P" {
            File LESARootFolder
            {
                DestinationPath="c:\LESA"
                SourcePath="$source\ProdLESA"
                Type="Directory"
                Ensure="Present"
                Recurse = $true
            }
            File ProgramFilesLESA
            {
                DestinationPath="C:\Program Files\LESA"
                Type="Directory"
                SourcePath="$source\Program Files\ProdLESA"
                Ensure="Present"
                Recurse=$true
            }
        }
    }


    # All servers have a c:\program files (x86)\lesa folder and subfolders, share and permissions.
    # These appear to be the same in every environment.
    File ProgramFilesx86LESA
    {
        DestinationPath="C:\Program Files (x86)\LESA"
        Type="Directory"
        SourcePath="$source\Program Files (x86)\LESA"
        Ensure="Present"
        Recurse=$true
    }

    # All servers have a LESAx86 share that points to the c:\program files (x86)\lesa folder.
    ss911_smbshare LESAx86Share
    {
        DependsOn="[File]ProgramFilesx86LESA"
        ShareName="LESAx86"
        SharePath="C:\Program Files (x86)\LESA"
        Ensure="Present"
    }

    # All servers have a LESA share that points to the c:\program files\lesa folder.
    ss911_smbshare LESAShare
    {
        DependsOn="[File]ProgramFilesLESA"
        ShareName="LESA"
        SharePath="C:\Program Files\LESA"
        Ensure="Present"
    }

    # Set file permissions on c:\program files\lesa and c:\program files (x86)\lesa according to environment
    # Dev and QA allow more permissions for developers
    switch -regex ($Node.Environment)
    {
        "D|Q" { 
            ss911_fileacl LESAPrivs
            {
                DependsOn="[File]ProgramFilesLESA"
                Path="C:\Program Files\LESA"
                Ensure="Present"
                ReadAccess="LESA\LESA-it-developers,LESA\Support Center"
                WriteAccess="LESA\LESA-it-developers,LESA\Support Center,LESA\LESAUtilities,LESA\DevBuild"
            }

            ss911_fileacl LESAx86Privs
            {
                DependsOn="[File]ProgramFilesx86LESA"
                Path="C:\Program Files (x86)\LESA"
                Ensure="Present"
                ReadAccess="LESA\LESA-it-developers,LESA\Support Center"
                WriteAccess="LESA\LESA-it-developers,LESA\Support Center,LESA\LESAUtilities,LESA\DevBuild"
            }

        }
        "P|T" { 
            ss911_fileacl LESAPrivs
            {
                DependsOn="[File]ProgramFilesLESA"
                Path="C:\Program Files\LESA"
                Ensure="Present"
                ReadAccess="LESA\LESA-it-developers,LESA\Support Center"
                WriteAccess="LESA\Dev Leads"
            }

            ss911_fileacl LESAx86Privs
            {
                DependsOn="[File]ProgramFilesx86LESA"
                Path="C:\Program Files (x86)\LESA"
                Ensure="Present"
                ReadAccess="LESA\LESA-it-developers,LESA\Support Center"
                WriteAccess="LESA\Dev Leads,LESA\LESAUtilities,LESA\DevBuild"
            }
        }
    }


    # Non-production servers each have a c:\lesa-<env> folder and a c:\program files\lesa-<env> folder
    # Production has a LESA-Production share that points to c:\LESA, with file permissions.
    switch -regex ($Node.environment) {
        "D" {
            File LESAEnv
            {
                DestinationPath="c:\LESA-Development"
                SourcePath="$source\LESA-Env"
                Type="Directory"
                Ensure="Present"
                Recurse=$true
            }
            File ProgramFilesLESAEnv
            {
                DestinationPath="c:\Program Files\LESA-Development"
                SourcePath="$source\Program Files\LESA-Env"
                Type="Directory"
                Ensure="Present"
                Recurse=$true
            }

            File ProgramFiles86xLESAEnv
            {
                DestinationPath="c:\Program Files (x86)\LESA-Development"
                SourcePath="$source\Program Files (x86)\LESA-Env"
                Type="Directory"
                Ensure="Present"
                Recurse=$true
            }

            ss911_smbshare LESAEnvShare
            {
                DependsOn="[File]ProgramFilesLESAEnv"
                ShareName="LESA-Development"
                SharePath="C:\Program Files\LESA-Development"
                Ensure="Present"
            }

            ss911_fileacl LESAEnvPrivs
            {
                DependsOn="[File]ProgramFilesLESAEnv"
                Path="C:\Program Files\LESA-Development"
                Ensure="Present"
                WriteAccess="LESA\LESA-it-developers,LESA\Support Center,LESA\LESAUtilities"
            }

        }
        "Q" {
            File LESAEnv
            {
                DestinationPath="c:\LESA-QualityAssurance"
                SourcePath="$source\LESA-Env"
                Type="Directory"
                Ensure="Present"
                Recurse=$true
            }
            File ProgramFilesLESAEnv
            {
                DestinationPath="c:\Program Files\LESA-QualityAssurance"
                Type="Directory"
                Ensure="Present"
                SourcePath="$source\program files\lesa-env"
                Recurse=$true
            }

            File ProgramFiles86xLESAEnv
            {
                DestinationPath="c:\Program Files (x86)\LESA-QualityAssurance"
                SourcePath="$source\Program Files (x86)\LESA-env"
                Type="Directory"
                Ensure="Present"
                Recurse=$true
            }

            ss911_smbshare LESAEnvShare
            {
                DependsOn="[File]ProgramFilesLESAEnv"
                ShareName="LESA-QualityAssurance"
                SharePath="C:\Program Files\LESA-QualityAssurance"
                Ensure="Present"
            }

            ss911_fileacl LESAEnvPrivs
            {
                DependsOn="[File]ProgramFilesLESAEnv"
                Path="C:\Program Files\LESA-QualityAssurance"
                Ensure="Present"
                WriteAccess="LESA\LESA-it-developers,LESA\Support Center,LESA\LESAUtilities"
            }
        }
        "T" {
            File LESAEnv
            {
                DestinationPath="c:\LESA-Training"
                SourcePath="$source\LESA-Env"
                Type="Directory"
                Ensure="Present"
                Recurse=$true
            }
            File ProgramFilesLESAEnv
            {
                DestinationPath="c:\Program Files\LESA-Training"
                Type="Directory"
                Ensure="Present"
                SourcePath="$source\program files\lesa-Env"
                Recurse=$true
            }

            File ProgramFiles86xLESAEnv
            {
                DestinationPath="c:\Program Files (x86)\LESA-Training"
                SourcePath="$source\Program Files (x86)\LESA-Env"
                Type="Directory"
                Ensure="Present"
                Recurse=$true
            }

            ss911_smbshare LESAEnvShare
            {
                DependsOn="[File]ProgramFilesLESAEnv"
                ShareName="LESA-Training"
                SharePath="C:\Program Files\LESA-Training"
                Ensure="Present"
            }

            ss911_fileacl LESAEnvPrivs
            {
                DependsOn="[File]ProgramFilesLESAEnv"
                Path="C:\Program Files\LESA-Training"
                Ensure="Present"
                ReadAccess="LESA\LESA-it-developers,LESA\Support Center"
                WriteAccess="LESA\LESAUtilities"
            }
        }
        "P" {
            ss911_smbshare LESAEnvShare
            {
                DependsOn="[File]LESARootFolder"
                ShareName="LESA-Production"
                SharePath="C:\LESA"
                Ensure="Present"
            }
            ss911_fileacl LESARootPrivs
            {
                DependsOn="[File]LESARootFolder"
                Path="C:\LESA"
                Ensure="Present"
                ReadAccess="LESA\LESA-it-developers,LESA\Support Center"
                WriteAccess="LESA\LESAUtilities"
            }
        }
    }


    #
    # Machine Config Settings
    #

    ss911_machineconfig MachineConfig 
    {
        Ensure="Present"
        Environment=$Env
    }


    #
    # Create Mode file at given path
    #

    ss911_Mode ProgramFilesMode 
    {
        Ensure="Present"
        Environment=$Node.Environment
        Path="c:\program files\lesa\lesadata"
    }

    ss911_Mode ProgramFilesx86Mode 
    {
        Ensure="Present"
        Environment=$Node.Environment
        Path="c:\program files (x86)\lesa\lesadata"
    }


    #
    # Local Administrators
    #

    switch -regex ($Node.Environment)
    {
        "D|Q" {
            ss911_LocalGroup Administrators
            {
                Ensure="Present"
                Name="Administrators"
                AdGroup="Administrators"
                MembersToInclude="lesa\lesa-it-developers","lesa\lesautilities"
            }
        }
        "P|T" {
            ss911_LocalGroup Administrators
            {
                Ensure="Present"
                Name="Administrators"
                AdGroup="Administrators"
                MembersToInclude="lesa\dev leads","lesa\lesautilities"
            }
        }
    }

    ####################################################################################
    # Warrants Auto Logon - Logon as LESA\LESAApp

    if ($Node.LESAAppAutoLogon)
    {

        Group Administrators
        {
            GroupName="Administrators"
            Ensure="Present"
            MembersToInclude="LESA\LESAApp"
            Credential=$credential
        }

        ss911_AutoLogon LESAApp
        {
            Ensure="Present"
            Login="lesa\lesaapp"
            Password="lesaapp"
        }
    }

    ####################################################################################
    # DVOUpload autorun

    if ($Node.RunDVOUpload)
    {
        ss911_AutoRunApp DVOUpload   
        {
            Ensure="Present"
            Login="lesa\lesaapp"
            Application="dvoupload.exe" 
            Path="c:\program files\warrantsuploaddvo"
        }
    }

    ####################################################################################
    # WarrantsUpload autorun

    if ($Node.RunWarrantsUpload)
    {
        ss911_AutoRunApp WarrantsUpload  
        {
            Ensure="Present"
            Login="lesa\lesaapp"
            Application="warrantupload.exe"
            Path="C:\Program Files\WarrantUpload"
        }
    }

    ####################################################################################
    # StateInterface autorun

    if ($Node.RunStateInterface)
    {
        ss911_AutoRunApp StateInterface  
        {
            Ensure="Present"
            Login="lesa\lesaapp"
            Application="stateinterface.exe"
            Path="C:\Program Files\stateinterface"
        }
    }

}


