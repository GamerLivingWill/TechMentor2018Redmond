<#
    DSC Configuration - LWINBaseServer
    Created by Will Anderson - Microsoft Cloud and Datacenter Management MVP
    June 2017
    Version 1.1.0.0
#>
    

Configuration LWINBaseConfig {


    Import-DscResource -ModuleName @{ModuleName = 'xPSDesiredStateConfiguration';ModuleVersion = '6.4.0.0'}
    Import-DscResource -ModuleName @{ModuleName = 'PSDesiredStateConfiguration';ModuleVersion = '1.1'}
    Import-DscResource -ModuleName @{ModuleName = 'xPendingReboot';ModuleVersion = '0.3.0.0'}

    $WireDataLocalPath = "C:\Installers\OMS\InstallDependencyAgent-Windows.exe"
    $WireDataArgs = '/S /RebootMode:rebootIfNeeded'

    

        WindowsFeature RSAT
        {
            Ensure = "Present"
            Name = "RSAT"

        }#EndWindowsFeature

        WindowsFeature RSATRoleTools
        {
            Ensure = "Present"
            Name = "RSAT-Role-Tools"
            DependsOn = "[WindowsFeature]RSAT"

        }#EndWindowsFeature

        WindowsFeature RSATADTools
        {
            Ensure = "Present"
            Name = "RSAT-AD-Tools"
            DependsOn = "[WindowsFeature]RSATRoleTools"

        }#EndWindowsFeature

        WindowsFeature RSATADPowerShell
        {
            Ensure = "Present"
            Name = "RSAT-AD-PowerShell"
            DependsOn = "[WindowsFeature]RSATADTools"

        }#EndWindowsFeature
        
        WindowsFeature RSATADDS
        {
            Ensure = "Present"
            Name = "RSAT-ADDS"
            DependsOn = "[WindowsFeature]RSATADPowerShell"

        }#EndWindowsFeature
        
        WindowsFeature RSATADAdminCenter
        {
            Ensure = "Present"
            Name = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]RSATADDS"

        }#EndWindowsFeature
        
        WindowsFeature RSATADDSTools
        {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]RSATADAdminCenter"

        }#EndWindowsFeature
        
        WindowsFeature RSATADLDS
        {
            Ensure = "Present"
            Name = "RSAT-ADLDS"
            DependsOn = "[WindowsFeature]RSATADDSTools"

        }#EndWindowsFeature

        Registry LegalNoticeCaption
        {
            Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\system'
            ValueName = 'legalnoticecaption'
            DependsOn = "[WindowsFeature]RSATADLDS"
            Ensure = 'Present'
            Force = $true
            ValueData = 'Welcome to Citrix on Azure by Coretek!'
            ValueType = 'String'
        }#EndRegistry

        Registry LegalNoticeText
        {
            
            Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\system'
            ValueName = 'legalnoticetext'
            DependsOn = "[Registry]LegalNoticeCaption"
            Ensure = 'Present'
            Force = $true
            ValueData = "This is an example of a fully configured environment using Configuration as Code."
            ValueType = 'String'

        }#EndRegistry


        User GuestAccountDisabled
        {
            
            UserName = 'Guest'
            DependsOn = '[Registry]LegalNoticeText'
            Disabled = $true
            Ensure = 'Present'

        }#EndUser

         Service OMSService
        {
            
            Name = "HealthService"
            State = "Running"

        }#EndService

        File Installers
        {
            DestinationPath = 'C:\Installers\'
            Ensure = 'Present'
            Type = 'Directory'
            DependsOn = "[Service]OMSService"

        }#File

        File OMSFolder
        {
            DestinationPath = 'C:\Installers\OMS'
            DependsOn = '[File]Installers'
            Ensure = 'Present'
            Type = 'Directory'

        }#File

 
        xRemoteFile OMSWireDataPackage {
            
            Uri = 'https://aka.ms/dependencyagentwindows'
            DestinationPath = $WireDataLocalPath
            DependsOn = '[File]OMSFolder'

        }#EndxRemoteFile

        xPackage OMSInstall {
            Ensure = "Present"
            Path  = $WireDataLocalPath
            Name = "Dependency Agent"
            ProductId = ""
            Arguments = $WireDataArgs
            DependsOn = "[xRemoteFile]OMSWireDataPackage"

        }#EndxPackage

        xPendingReboot PostSEPRebootCheck
        {
            Name = 'PostSEPRebootCheck'
            DependsOn = "[xPackage]OMSInstall"

        }#EndxPendingReboot

}#EndConfiguration

#BaseConfig -OMSWorkspaceKey $OMSWorkspaceKey -OMSWorkspaceID $OMSWorkspaceID