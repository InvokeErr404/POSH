<#
.SYNOPSIS
Offboards a user account in active directory.
 
.DESCRIPTION
This will disable a user in Active Directory automatically with Powershell. Syncing to AAD and removing O365 licenses.
 
.NOTES
Name: AD-Offboard
Version: 2.08
Author: InvokeErr404
Date of last revision: 07/11/2024

.ORIGINAL CODE
Inspired By: The Sysadmin Channel
Author: Logan Simmons

.NOTES
2.0  - Initial Release (Rework of original script)
2.01 - Added a few Write-Host prompts to notify admin of tasks being done. Added a few sleeps to fix group sync error when removing groups from user.
2.02 - Fixed auto reply config for manager variable.
2.03 - Updated Domain Controller to New Domain Controller. Fixed error on -InformationAction when disconnecting from ExchangeOnline
2.04 - Tweaked Membership removal to fix errors on distribution lists. Fixed permission removal error of "All Users" group and dynamic groups in AAD.
2.05 - Added prompt for giving delegated user access to offboarded user's personal OneDrive.
2.06 - Changed bounceback to display manager name instead of email (per CIO's Request).
2.07 - Updated bounceback to include ALL external senders and not just those in user's contact list.
2.08 - Removed duplicate bounce back email variable and adjusted variables on prompt. Resulted in custom email not applying prior to change.
#>

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

# Checking if running as admin & proper modules are installed.
#Requires -RunAsAdministrator

# Checking for required Modules. Installing if not present
# ActiveDirectory
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Write-Host "ActiveDirectory Already Installed"
} 
else {
    try {
        Install-Module -Name ActiveDirectory -AllowClobber -Confirm:$False -Force  
    }
    catch [Exception] {
        $_.message 
        exit
    }
}

# Microsoft Graph SDK
if (Get-Module -ListAvailable -Name Microsoft.Graph) {
    Write-Host "Microsoft Graph SDK Already Installed"
} 
else {
    try {
        Install-Module -Name Microsoft.Graph -Scope AllUsers -AllowClobber -Confirm:$False -Force
        Import-Module Microsoft.Graph.Users
        Import-Module Microsoft.Graph.Groups
    }
    catch [Exception] {
        $_.message 
        exit
    }
}

# Write Warning
Write-Host "There is a 60 second sleep command in the middle of the script, please don't panic." -ForegroundColor Green
Start-Sleep 3
Clear-Host
Write-Host "Logging into O365/Online Services as Admin..." -ForegroundColor Green
# Importing modules and connecting
Import-Module ActiveDirectory -ErrorAction Stop
# Connect to MgGraph
Connect-MgGraph -Scopes User.ReadWrite.All, GroupMember.ReadWrite.All, Group.ReadWrite.All, Organization.Read.All, Directory.Read.All -ErrorAction Stop
# Connect to Exchange Online
$acctName = $env:UserName+"@contoso.com"
Connect-ExchangeOnline -UserPrincipalName $acctName -ShowBanner:$false -ShowProgress $true
Clear-Host

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

$ADServer = "DC1.contoso.com"

# Get the user object
Do {
    #Enter SamAccountName or full name of user (full name needs to be an exact match, not case sensitive)
    $name = Read-Host 'Enter username or full name of user (full name must be an exact match)'
    Clear-Host
    #Get user from AD, filter SamAccountName OR full name
    $user = Get-ADUser -Filter "samaccountname -eq '$name' -OR name -eq '$name'"
    
    #Check if user was found and output the result
    If (!$user) {
        "This user does not exist in AD"
    } 
    Else {
        $prompt = Read-Host "$($user.name) : Is this who you want to terminate? (Y/N)"
        switch ($prompt) {
            'Y' {
                $user
        }
            'N' {Clear-Host}
    }
}
    #End if admin confirms exists, otherwise go to top and try again
    } Until (($prompt) -eq 'Y')

Clear-Host
Write-Host "Disabling and Moving User..." -ForegroundColor Yellow
Start-Sleep 5

# Disable the account
Disable-ADAccount -Identity $user.SamAccountName -Server $ADServer

# Change the password to something random
$newPassword = ConvertTo-SecureString -AsPlainText -Force (New-Guid).Guid # Random password using a GUID, making it both unique and difficult to guess.
Set-ADAccountPassword -Identity $user.SamAccountName -NewPassword $newPassword -Server $ADServer

# Remove all memberships except "Domain Users"
Write-Host "Removing User's Memberships..." -ForegroundColor Yellow
$memberships = Get-ADPrincipalGroupMembership -Identity $user.SamAccountName -Server $ADServer
foreach ($membership in $memberships) {
    if ($membership.Name -ne "Domain Users") {
        Remove-ADPrincipalGroupMembership -Identity $user.SamAccountName -MemberOf $membership -Server $ADServer -Confirm:$false
    }
}
Start-Sleep 10
Clear-Host

# Get the manager attribute for later
$getmanager = Get-ADUser -Identity $user.SamAccountName -Properties Manager
$managerDN = $getmanager.manager
if ($managerDN) {
    $manager = Get-ADUser -Identity $managerDN -Properties UserPrincipalName -ErrorAction SilentlyContinue
    $managerUPN = $manager.UserPrincipalName
}
else {
    $managerUPN = "[COMPANY NAME] HR"
}

# Remove the manager attribute
Set-ADUser -Identity $user.SamAccountName -Manager $null -Server $ADServer

# Set the user's description to their title with the current date
$title = (Get-ADUser $user.SamAccountName -Properties title).title
$date = Get-Date -Format "MM-dd-yyyy"
$description = "$title ($date)"
Set-ADUser -Identity $user.SamAccountName -Description $description -Server $ADServer

# Move the user to the "Disabled Accounts" OU
$OU = "OU=Disabled Accounts,DC=contoso,DC=com"
Move-ADObject -Identity $user.DistinguishedName -TargetPath $OU -Server $ADServer

# Remove from Broadcast
Write-Host "Removing User from Broadcast" -ForegroundColor Green
Set-ADUser -Identity $user.SamAccountName -Remove @{extensionAttribute15="Broadcast"} -Server $ADServer
Start-Sleep 10

#Hide from GAL
Write-Host "Removing from Global Address List in Exchange" -ForegroundColor Green
Start-Sleep 2
Set-ADUser -Server $ADServer -Identity $user.SamAccountName -Add @{msExchHideFromAddressLists="TRUE"}
Clear-Host

# Syncing the AD
Invoke-Command -ComputerName HYBRID_SYNC_SERVER {Start-ADSyncSyncCycle -PolicyType Delta}
Write-Host "Sleeping...Please Wait 60 seconds." -ForegroundColor Red
Start-Sleep 60

# Convert the account to a shared mailbox
Set-Mailbox -Identity $user.UserPrincipalName -Type Shared

# Set an auto-reply on the mailbox
$autoreply = Read-Host -Prompt "Script sets an automated bounce back email. Would you like to set a custom one?          
    Yes [Y]   No [N]" 
switch ($autoreply) { 
    'Y' { $cstmessage = Read-Host -Prompt "Type out your custom bounce back."
    Write-Host "Setting Bounceback email for $($User.Name)" -ForegroundColor Green
    Set-MailboxAutoReplyConfiguration -Identity $user.UserPrincipalName -AutoReplyState Enabled -InternalMessage $cstmessage -ExternalMessage $cstmessage -ExternalAudience All
    Start-Sleep 5
    Clear-Host }
    'N' { $message = @"
    <b>THIS IS AN AUTOMATED RESPONSE:</b>
    <br><br>
    This email is no longer monitored by [COMPANY NAME].
    <br>
    Please contact $managerUPN for assistance on your inquiry. 
    <br><br>
    Regards,
    <br> 
    [COMPANY NAME] IT
"@
    Write-Host "Setting Bounceback email for $($User.Name)" -ForegroundColor Green
    Set-MailboxAutoReplyConfiguration -Identity $user.UserPrincipalName -AutoReplyState Enabled -InternalMessage $message -ExternalMessage $message -ExternalAudience All
    Start-Sleep 5
    Clear-Host }
}

# Prompt for delegation
$delegateprompt = Read-Host "Do you want to set delegation for this mailbox? (Y/N)"
if ($delegateprompt -eq "y") { Do {
    $delname = Read-Host "Enter SamAccountName or FULL Name of user (must be an exact match)"
    $delegate = Get-ADUser -Filter "samaccountname -eq '$delname' -OR name -eq '$delname'"
    If (!$delegate) {
            "This user does not exist in AD"
    }
    Else {
        $delegateconfirm = Read-Host "$($delegate.name) : Is this who you want to give mailbox delegation to? (Y/N)"
        switch ($delegateconfirm) {
            'Y' { Add-MailboxPermission -Identity $user.SamAccountName -User $delegate.SamAccountName -AccessRights FullAccess -AutoMapping:$true
            Continue }
        
            'N' {Clear-Host}
}}}Until (($delegateconfirm) -eq 'Y')

# Prompt for OneDrive/SharePoint delegation
$delegateoneprompt = Read-Host "Do you want to set delegation for OneDrive/Personal SharePoint? (Y/N)"
if ($delegateoneprompt -eq "y") { Do {
        switch ($delegateoneconfirm) {
            'Y' {
                $offboardedUserUPN = (Get-ADUser -Identity $user.SamAccountName -Properties mail).mail
                $delegateUPN = (Get-ADUser -Identity $delegate.SamAccountName -Properties mail).mail
                
                # Assign the OneDrive delegation. Adjust the roles as per your requirement
                # Example role could be "write", "read", etc. - This depends on the exact requirements and available roles
                $delegationRole = "write"
                Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/users/$offboardedUserUPN/drive/items/root/permissions" -Body (@{
                    "grantees" = @(@{"email" = "$delegateUPN"})
                    "roles" = @("$delegationRole")
                } | ConvertTo-Json) -ContentType "application/json"
                
                # Note: You might need to adjust the URI/path based on the specific SharePoint site/item
                Continue 
            }
        
            'N' {Clear-Host}
        }
} Until (($delegateconfirm) -eq 'Y')
}}

# Remove From Azure Groups (Teams Included)
$ErrorsLogFile = 'C:\temp\logs\AD-OffboardError.log'
Write-Host "Removing $($user.Name) from all AAD Groups (MS Teams Included)" -ForegroundColor Yellow

$userId = (Get-MgUser -UserId $user.UserPrincipalName).Id
$groups = Get-MgUserMemberOf -UserId $userId | Where-Object { $_.groupTypes -notcontains 'DynamicMembership' -and $_.additionalProperties['displayName'] -ne "All Users" }

# Iterate through the list of groups and remove the user from each group
foreach ($group in $groups) {
    try{ 
        Remove-MgGroupMemberByRef -GroupId $group.Id -DirectoryObjectId $userId -ErrorVariable MemberRemovalErr
        if($MemberRemovalErr)
    {
        Remove-DistributionGroupMember -Identity $group.id -Member $userId -BypassSecurityGroupManagerCheck -Confirm:$false
    }
}
      catch{
        $ErrorLog = "$($user.UserPrincipalName) - GroupId($($Membership.Id)) - Remove Group Memberships Action - "+$Error[0].Exception.Message  
        $ErrorLog>>$ErrorsLogFile
    }
}

# Verify that the user has been removed from all groups
$remainingGroups = Get-MgUserMemberOf -UserId $userId | Where-Object { $_.groupTypes -notcontains 'DynamicMembership' -and $_.additionalProperties['displayName'] -ne "All Users" }

if ($remainingGroups.Count -eq 0) {
    Write-Host "Successfully removed user $($user.Name) from all groups" -ForegroundColor Green
} else {
    Write-Host "User $($user.Name) is still a member of the following groups: " -ForegroundColor Red
    $remainingGroups | ForEach-Object {
        [pscustomobject]@{
            displayName = $_.additionalProperties['displayName']
        }
    }
}
Read-Host -Prompt "Press Enter to Continue"
Clear-Host

# Remove licenses from the offboarded user
$licenses = Get-MgUserLicenseDetail -UserId $user.UserPrincipalName | Select-Object SkuId -ErrorAction SilentlyContinue
if (!$licenses) { Write-Host "No Licenses found for $($user.Name), skipping..." -ForegroundColor Yellow; continue }
foreach ($license in $licenses) {
        Set-MgUserLicense -UserId $user.UserPrincipalName -AddLicenses @() -RemoveLicenses $license.SkuId -ErrorAction Stop
    }
Start-Sleep 5    
Clear-Host

# Close out
Disconnect-MgGraph | Out-Null
Disconnect-ExchangeOnline -Confirm:$False -InformationAction SilentlyContinue | Out-Null
Write-Host $User.name "has been disabled. Please go to admin.microsoft.com to complete any additional tasks." -ForegroundColor Green
Read-Host -Prompt "Press Enter to Exit"
