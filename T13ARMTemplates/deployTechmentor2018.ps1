Add-AzureRmAccount
$Subscription = 'LastWordInNerd'
$Sub = Get-AzureRmSubscription -SubscriptionName $Subscription
Set-AzureRmContext -SubscriptionName $Sub.Name

$TemplateLoc = 'C:\Users\willa\Documents\GitHub\TechMentor2018Redmond\T13ARMTemplates\ARMTemplates.json'
$BaseName = 'tm2018'
$Location = 'westus'
$AutoAcctName = 'mms-eus'
$AutoAcctResGrpName = 'testautoaccteastus2'

$ResGrp = New-AzureRmResourceGroup -Name $BaseName -Location $Location -Verbose

$AutoAcctDeployment = Get-AzureRmAutomationAccount -ResourceGroupName $AutoAcctName -Name $AutoAcctResGrpName
$AutoAcctReg = Get-AzureRmAutomationRegistrationInfo -ResourceGroupName $AutoAcctDeployment.ResourceGroupName -AutomationAccountName $AutoAcctDeployment.AutomationAccountName

$Secret = Get-AzureKeyVaultSecret -VaultName 'testkeyvautleus2' -Name 'lwinadmin'

$DeploymentTemplateParams = @{

    #'location' = $ResGrp.location
    #'environment' = 'np'
    'automationRegistrationUrl' = $AutoAcctReg.Endpoint
    'automationRegistrationKey' = $AutoAcctReg.PrimaryKey
    'adminPass' = $Secret.SecretValue
    'adminUser' = $Secret.Name

}


Test-AzureRmResourceGroupDeployment -ResourceGroupName $ResGrp.ResourceGroupName -TemplateFile $TemplateLoc -TemplateParameterObject $DeploymentTemplateParams -Verbose
New-AzureRmResourceGroupDeployment -ResourceGroupName $ResGrp.ResourceGroupName -TemplateFile $TemplateLoc -TemplateParameterObject $DeploymentTemplateParams -Verbose

New-AzureRmResourceGroupDeployment -ResourceGroupName $ResGrp.ResourceGroupName -TemplateFile $TemplateLoc -TemplateParameterObject $DeploymentTemplateParams


Measure-Command {New-AzureRmResourceGroupDeployment -ResourceGroupName $ResGrp.ResourceGroupName -TemplateFile $TemplateLoc -TemplateParameterObject $DeploymentTemplateParams -DeploymentDebugLogLevel All}
