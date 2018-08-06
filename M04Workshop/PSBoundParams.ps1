Param(

    [parameter()][string]$Password=$null,
    [parameter()][string]$GivenName=$null,
    [parameter()][string]$Surname=$null,
    [parameter()][string]$GroupName=$null,
    [parameter(Mandatory=$true)][string]$UserPrincipalName

)

$AutomationCred = Get-AutomationPSCredential -Name 'myautoCred'

#Converting Plaintext Password Object to SecureString
If ($Password.value -eq $null){

    $pwd = $null

}
Else {

    $pwd = ConvertTo-SecureString $Password -AsPlainText -Force

}

#Creating Hashtable to add inputs to if needed.
$InputHashtable = @{

}

#Getting User Record to be Changed.
$User = Get-ADUser -Identity $UserPrincipalName -Properties memberOf


#Getting Input Parameters for User Record Change
foreach($Param in $PSBoundParameters.GetEnumerator()){

    If($Param.Key -ne 'UserPrincipalName' -and $Param.Key -ne 'GroupName' -and $Param.Key -ne 'Password'){
    
        $InputHashtable.Add($Param.Key,$Param.Value)

    }

}


#Updating User Record if Needed.
If ($InputHashtable.Keys.Count -ne 0){

    Set-ADUser -Identity $User @InputHashTable    
    
}
Else{

    Write-Output "User record does not require changes."

}

If($pwd -ne $null){

    Set-ADAccountPassword -Identity $User.SamAccountName -Reset -NewPassword $pwd -Credential $AutomationCred

}
Else{

    Write-Output "Password field is null.  No Update required."

}

#Updating Group Record If Needed.
If($GroupName -ne $null){

    ForEach ($Group in $User.MemberOf){

        Remove-ADGroupMember -Identity $Group -Members $User.UserPrincipalName -Confirm:$false

    }

    $Group = Get-AdGroup -Identity $GroupName
    Add-ADGroupMember -Identity $Group -Members $User

}


$SyncSched = Get-ADSyncScheduler

$CurrentTimeUtc = (Get-Date).ToUniversalTime()

If ($CurrentTimeUtc.AddMinutes(+10) -lt $SyncSched.NextSyncCycleStartTimeInUTC){

    $ADSyncTask = Get-ScheduledTask -TaskPath '\AutomationTasks\' -TaskName 'TriggerADSync'
    $Trigger = New-ScheduledTaskTrigger -At $CurrentTimeUtc.AddMinutes(+10) -Once
    Set-ScheduledTask -TaskPath $ADSyncTask.TaskPath -TaskName $ADSyncTask.TaskName -Trigger $Trigger -Password $AutomationCred.GetNetworkCredential().Password -User $AutomationCred.UserName

}