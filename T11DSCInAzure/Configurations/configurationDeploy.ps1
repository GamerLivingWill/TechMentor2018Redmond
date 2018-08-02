#region Login

Add-AzureRmAccount
$Subscription = 'LastWordInNerd'
$Sub = Get-AzureRmSubscription -SubscriptionName $Subscription
Set-AzureRmContext -SubscriptionName $Sub.Name

#endregion

#region stuff you'll want to change
$ConfigLocation = 'C:\Users\willa\Documents\GitHub\TechMentor2018Redmond\Configurations\Techmentor2018Config.ps1'
$ConfigName = 'Techmentor2018Config'
$AutoAcctResourceGroupName = 'mms-eus'

#endregion

#region GetAutomationAccount

$AutoResGrp = Get-AzureRmResourceGroup -Name $AutoAcctResourceGroupName
$AutoAcct = Get-AzureRmAutomationAccount -ResourceGroupName $AutoResGrp.ResourceGroupName

#endregion

#region Access blob container

$StorAcct = (Get-AzureRmStorageAccount -ResourceGroupName $AutoAcct.ResourceGroupName).where({$PSItem.StorageAccountName -eq 'modulestor'})

Add-AzureAccount
$AzureSubscription = ((Get-AzureSubscription).where({$PSItem.SubscriptionName -eq $Subscription})) 
Select-AzureSubscription -SubscriptionName $AzureSubscription.SubscriptionName -Current
$StorKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $StorAcct.ResourceGroupName -Name $StorAcct.StorageAccountName).where({$PSItem.KeyName -eq 'key1'})
$StorContext = New-AzureStorageContext -StorageAccountName $StorAcct.StorageAccountName -StorageAccountKey $StorKey.Value
$Container = Get-AzureStorageContainer -Name ('modules') -Context $StorContext


#endregion

#region upload zip files



$ModulesToUpload = Get-ChildItem -Filter "*.zip"

ForEach ($Mod in $ModulesToUpload){

        $Blob = Set-AzureStorageBlobContent -Context $StorContext -Container $Container.Name -File $Mod.FullName -Force
        
        New-AzureRmAutomationModule -ResourceGroupName $AutoAcct.ResourceGroupName -AutomationAccountName $AutoAcct.AutomationAccountName -Name ($Mod.Name).Replace('.zip','') -ContentLink $Blob.ICloudBlob.Uri.AbsoluteUri

}


#endregion

#region Import Composite Configuration

#***NOTE*** - Configuration Name must match Configuration Script Name
$Config = Import-AzureRmAutomationDscConfiguration -SourcePath (Get-Item $ConfigLocation).FullName -AutomationAccountName $AutoAcct.AutomationAccountName -ResourceGroupName $AutoAcct.ResourceGroupName -Description $ConfigName -Published -Force -Verbose

#endregion

#region Compile your config

$ConfigData = 
@{
    AllNodes = 
    @(
        @{
            NodeName = "*"
        }

        @{
            NodeName     = "DSCTarget"
            Role         = "DSCTarget"
        }
    )
}

$DSCComp = Start-AzureRmAutomationDscCompilationJob -AutomationAccountName $AutoAcct.AutomationAccountName -ConfigurationName $Config.Name -ConfigurationData $ConfigData -Parameters $Parameters -ResourceGroupName $AutoAcct.ResourceGroupName -Verbose

Get-AzureRmAutomationDscCompilationJob -Id $DSCComp.Id -ResourceGroupName $AutoAcct.ResourceGroupName -AutomationAccountName $AutoAcct.AutomationAccountName -Verbose

#endregion