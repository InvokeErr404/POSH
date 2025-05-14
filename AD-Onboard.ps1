<#
.SYNOPSIS
Onboards a user account in active directory with information entered in by the admin.
 
.DESCRIPTION
This will create a user in Active Directory automatically with Powershell. Syncing to AAD and adding O365 licenses if desired.
 
.NOTES
Name: AD-Onboard
Version: 2.3.5
Author: InvokeErr404
Date of last revision: 04/18/2025

.ORIGINAL CODE
Inspired By: The Sysadmin Channel
Author: Logan Simmons

.NOTES
2.0  - Initial Release (Rework of original script)
2.01 - Fixed secure password parameter. Fixed "get user id " for changing usage location. Fixed copying memberships for on-prem and cloud
2.02 - Updated variables for helpdesk@contoso.com. Fixed password variable output. Added team member to onboarding email
2.03 - Added command to add user to helpdesk customer group.
2.04 - Fixed onboard email auth for sending welcome email. Trimmed down email contents and added Cisco  Quick Guide PDF to email.
2.1.0 - Added default addresses and #'s for departments (change in AD if desired). Added the copying of source user's M365 groups to new user. Fixed search query for manager and copy source user.
2.1.1 - Fixed number attribute for user. Changed AD Server to New Domain Controller.
2.1.2 - Removed duplicate flag in New-ADUser cmdlet.
2.1.3 - Removed test commands that caused issues with command running. -Country parameter specifically needs the two-letter ISO 3166 code (US) to apply the attribute correctly
2.2.0 - Reworked the entire group/permissions section- allowing you to skip copying groups/permissions from a source user and setting up an account without inheriting any memberships/access automatically. Add the user to the groups manually.
        All new users will be added to an MFA Requirement Group
2.2.1 - Adjusted module checks with "Get-InstalledModule" along with a minimum required version for Microsoft.Graph
2.2.2 - Bracketing format error when copy user failed to find user, causing the onboard process to skip multiple steps and then ask for license information.
2.3.0 - Created a prompt for sending new users an email to their personal email with temp creds and MFA setup.
2.3.1 - Updated email app password. Old one either is wrong or is obsolete. This prevented emails to personal emails as well as onboarding emails to work ones.
2.3.2 - Updated script to handle copying M365 groups from source user properly. This wasn't working properly due to my original "for each" loop.
2.3.3 - Revised Copy Source User section and Manager Set section to error and prompt retry if source user is disabled/inactive.
2.3.4 - Fixed spelling error for Sheriff Admin OU
2.3.5 - Fixed Remote Routing Adress to be "contoso.mail.onmicrosoft.com" with an added variable in the ADUserParams' array (This is per the required/reccomended MSFT way of doing thing to ensure correct EXO routing).
#>

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

# Checking if running as admin & proper modules are installed.
#Requires -RunAsAdministrator

# Checking for required Modules. Installing if not present
# ActiveDirectory
if (Get-Module -Name ActiveDirectory) {
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
if (Get-InstalledModule -Name Microsoft.Graph -MinimumVersion 2.8.0) {
    Write-Host "Microsoft Graph SDK Already Installed"
} 
else {
    try {
        Install-Module -Name Microsoft.Graph -Scope AllUsers -AllowClobber -Confirm:$False -Force
    }
    catch [Exception] {
        $_.message 
        exit
    }
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

# Setting Parameters and Custom Scripts
# Server to run commands to
$ADServer = "DC1.contoso.local"

# Setting the variable for the domain.
$Domain = "contoso.com"

# Password Generator
$RandomPW = Invoke-RestMethod -uri "https://www.dinopass.com/password/simple"
$Special = "!@#$%^&*".ToCharArray()
$Password = $RandomPW+($Special | Get-Random -count 1)

# Importing Required Modules and Connecting
Import-Module ActiveDirectory -ErrorAction Stop
Connect-MgGraph -Scopes User.ReadWrite.All, GroupMember.ReadWrite.All, Organization.Read.All -ErrorAction Stop

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

# First Name
$GivenName = Read-Host "Enter in the First Name"
# Last Name
$Surname = Read-Host "Enter in the Last Name"
# Full Name
$Name = "$GivenName $Surname"
# Set SamAccountName
$i = 1
$SamAccountName = $GivenName.substring(0,$i) + $Surname
# Confirmation for $SamAccountName
Do { $SamNameconfirm = Read-Host -Prompt "Username is $SamAccountName. Is this correct?          
    Yes [Y]   No [N]" 
switch ($SamNameConfirm) { 
    'Y' { $SamAccountName }       
    'N' { $SamAccountName = Read-Host "Enter new username" }
}
} Until (($SamNameConfirm) -eq 'Y')

Write-Host "Username is set to $SamAccountName." -ForegroundColor Green
Clear-Host
# Check to see if user account already exists
do
{
  if ($(Get-ADUser -Server $ADServer -Filter { SamAccountName -eq $SamAccountName }))  {
    Write-Host "WARNING: Logon name" $SamAccountName.ToUpper() "already exists. Adding next character in first name" -ForegroundColor Red
    Write-Host "Changing SamAccountName to" $($GivenName.substring(0,$i++) + $Surname) -ForegroundColor Green
    $SamAccountName = $GivenName.substring(0,$i++) + $Surname
    Write-Host
    $taken = $true
    Start-Sleep 10
  } else {
    $taken = $false
  }
} until ($taken -eq $false)
$SamAccountName = $SamAccountName.ToLower()
Clear-Host

# Set employee ID
Do { $EmpID = Read-Host "Enter in the Employee ID"
$IDconfirm = Read-Host -Prompt "Employee ID is set as $EmpID. Is this correct? 
Yes [Y]   No [N]"
switch ($IDconfirm) { 
    'Y' { $EmpID }       
    'N' { Clear-Host }
}
} Until (($IDconfirm) -eq 'Y')
Clear-Host

# Set Description/Job title
$Description = Read-Host -Prompt "Enter in the User's job title. This will also be their description."
# Department OU Menu
function Show-Menu
{
    param (
        [string]$Title = 'Department Selection'
    )
    Clear-Host
  Write-Host "====================================================="
  Write-Host "      Please choose a Department to assign $Name to.  "
  Write-Host
  Write-Host "            Devision Departments                 " -ForegroundColor Yellow
  Write-Host
  Write-Host "  Department 1:   '1'       Department 2:    '2' "
  Write-Host "  :               '3'       :                '4' "
  Write-Host "  :               '5'       :                '6' "  
  Write-Host "  :               '7'       :                '8' "     
  Write-Host "  :               '9'       :               '10' "
  Write-Host "  :              '11'       :               '12' "
  Write-Host "  :              '13'       :               '14' "
  Write-Host "  :              '15'       :               '16' "
  Write-Host "  :              '17'       :               '18' "
  Write-Host "  :              '19'       :               '20' "
  Write-Host "  :              '21'                            "
  Write-Host
  Write-Host "              Other Division Departments         " -ForegroundColor Yellow
  Write-Host
  Write-Host "  :              '22'       :               '23' "
  Write-Host "  :              '24'       :               '25' "
  Write-Host "  :              '26'       :               '27' "
  Write-Host "  :              '28'                            "
  Write-Host
  Write-Host "===================================================="
}

# Department Selection
Show-Menu -Title 'Department Selection'
 $selection = Read-Host "Please make a selection"
 switch ($selection)
 {
     '1' {
         $Department = 'DEPARTMENT_NAME'
         $UsersOU = 'OU=Department,OU=Users,DC=contoso,DC=com'
         $OfficeA = '123 Contoso St.'
         $OfficeP = '800-555-1234'
     } '2' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '3' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '4' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '5' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '6' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '7' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '8' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '9' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '10' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '11' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '12' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '13' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '14' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '15' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '16' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '17' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '18' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '19' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '20' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '21' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '22' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '23' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '24' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '25' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '26' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '27' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
     } '28' {
         $Department = ''
         $UsersOU = ''
         $OfficeA = ''
         $OfficeP = ''
         Write-Host "Manually move to proper sub OU if applicable (School, Reserve, Retired)" -ForegroundColor Yellow # For department with multiple subdivisions (logic to prompt reminder)
     }
 }

# Setting Manager
Do {
    # Enter SamAccountName or full name of user (first and last)
    $Manager = Read-Host "Enter SamAccountName or First and Last name of user that $Name reports to"
    Clear-Host
    # Split input by space
    $Mgrnames = $Manager -split ' '
    $Mgrfilter = if ($Mgrnames.Count -eq 2) {
        # If we have exactly two names (first and last), then construct the GivenName and Surname filter
        $MgrfirstName = $Mgrnames[0]
        $MgrlastName = $Mgrnames[1]
        "GivenName -eq '$MgrfirstName' -and Surname -eq '$MgrlastName'"
    } else {
        # Otherwise, use SamAccountName or Name filter
        "SamAccountName -eq '$Manager' -or Name -eq '$Manager'"
    }

    # Get user from AD, filter by SamAccountName OR full name, including the Enabled property
    $ManagerUser = Get-ADUser -Filter $Mgrfilter -Properties Enabled
    # Check if user was found and if the account is enabled
    If (!$ManagerUser) {
        Write-Host "This user does NOT exist in AD. Please try again."
    } elseif (-not $ManagerUser.Enabled) {
        Write-Host "The account for $($ManagerUser.Name) is disabled. Please try again with an active account."
    } Else {
        $ManagerPrompt = Read-Host "$($ManagerUser.Name) : Is this who $Name will report to? (Y/N)"
        switch ($ManagerPrompt) {
            'Y' {
                $Manager = $ManagerUser.SamAccountName
            }
            'N' {Clear-Host}
        }
    }
} 
# End if admin confirms, otherwise go to top and try again
Until (($ManagerPrompt) -eq 'Y' -and $ManagerUser.Enabled)
Set-ADUser -Identity $SamAccountName -Manager $Manager
Clear-Host

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

# Set on-prem user account parameters
$ADUserParams = @{
    Path = "$UsersOU"
    SamAccountName = "$SamAccountName"
    Name = "$Name"
    GivenName = "$GivenName"
    Surname = "$Surname"
    UserPrincipalName = "$SamAccountName@$Domain"
    MSFTRemoteMB = "$SamAccountName@contoso.mail.onmicrosoft.com"
    AccountPassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    Title = "$Description"
    Description = "$Description"
    Department = "$Department"
    EmployeeID = "$EmpID"
    EmployeeNumber = "$EmpID"
    Manager = "$Manager"
    Address = "$OfficeA"
    City = "New York"
    State = "NY"
    Zip = "10001"
    Country = "US"
    Phone ="$OfficeP"
}

# Create on-prem user account
New-ADUser -Server $ADServer -Name $ADUserParams.Name -GivenName $ADUserParams.GivenName -Surname $ADUserParams.Surname `
-DisplayName $ADUserParams.Name -SamAccountName $ADUserParams.SamAccountName -UserPrincipalName $ADUserParams.UserPrincipalName `
-AccountPassword $ADUserParams.AccountPassword -Path $ADUserParams.Path -Description $ADUserParams.Description `
-Title $ADUserParams.Title -Department $ADUserParams.Department -EmployeeID $ADUserParams.EmployeeID -Manager $ADUserParams.Manager `
-StreetAddress $ADUserParams.Address -City $ADUserParams.City -State $ADUserParams.State -PostalCode $ADUserParams.Zip `
-Country $ADUserParams.Country -Office $ADUserParams. -Enabled $true -ChangePasswordAtLogon $true -Confirm:$false

Write-Host "Creating new user...please wait" -ForegroundColor Yellow
Start-Sleep 15

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

# Copy AD membership from one user to another - with option to skip
$copyGroups = Read-Host "Do you want to copy groups/permissions from another user? (Y/N)"
if ($copyGroups -eq 'Y') {
    Do {
        # Login name of user to copy FROM

        # Enter SamAccountName or full name of user (first and last)
        $Source = Read-Host "Enter SamAccountName or First and Last name of user you want to COPY memberships FROM"
        Clear-Host
        # Split input by space
        $Srcnames = $Source -split ' '
        $Srcfilter = if ($Srcnames.Count -eq 2) {
            # If we have exactly two names (first and last), then construct the GivenName and Surname filter
            $SrcfirstName = $Srcnames[0]
            $SrclastName = $Srcnames[1]
            "GivenName -eq '$SrcfirstName' -and Surname -eq '$SrclastName'"
        } else {
            # Otherwise, use SamAccountName or Name filter
            "SamAccountName -eq '$Source' -or Name -eq '$Source'"
        }
    
        # Get user from AD, filter by SamAccountName OR full name
        $SourceUser = Get-ADUser -Filter $Srcfilter -Properties Enabled
        # Check if user was found and if the account is enabled
        If (!$SourceUser) {
            Write-Host "This user does NOT exist in AD. Please try again."
        } elseif (-not $SourceUser.Enabled) {
            Write-Host "The account for $($SourceUser.Name) is disabled. Please try again with an active account."
        } Else {
            $CopyPrompt = Read-Host "$($SourceUser.Name) : Is this who you want to copy memberships from? (Y/N)"
            switch ($CopyPrompt) {
                'Y' {
                    $Source = $SourceUser.UserPrincipalName
                }
                'N' {Clear-Host}
            }
        }
    }
# End if admin confirms, otherwise go to top and try again
Until (($CopyPrompt) -eq 'Y' -and $SourceUser.Enabled)
}


# Write User for copy
Write-Host "Copying membership permissions based on entry..."

# Get membership of Source User and add to New User
Get-ADUser -Server $ADServer -Identity $SourceUser.SamAccountName -Properties memberof | Select-Object memberof -ExpandProperty memberof | Add-ADGroupMember -Server $ADServer -Members $SamAccountName
Start-Sleep 5

# Setting Broadcast Attribute for email
Set-ADUser -Server $ADServer -Identity $SamAccountName -Add @{extensionAttribute15="Broadcast"}

# Add user to Helpdesk Customers Group
$helpdeskgroup = "Helpdesk Customers"
Add-ADGroupMember -Identity $helpdeskgroup -Members $SamAccountName

# Connecting to a Powershell session in EXCHANGE_ONPREM_SERVER and create an Office365 mailbox link
$OnPremSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://EXCHANGE_ONPREM_SERVER/powershell -Authentication Kerberos
Import-PSSession $OnPremSession -DisableNameChecking -AllowClobber
Enable-RemoteMailbox -Identity $SamAccountName -RemoteRoutingAddress $ADUserParams.UserPrincipalName -DomainController $ADServer

# HYBRID_SYNC_SERVER Delta Sync
Invoke-Command -ComputerName HYBRID_SYNC_SERVER -ScriptBlock { Start-ADSyncSyncCycle -PolicyType delta }
Read-Host -Prompt "Press Enter to sync On-Prem with O365"
Clear-Host
Write-Host "Please wait 60 seconds while On-Prem and O365 sync"
Start-Sleep 60
Clear-Host

# Write User for copy
Write-Host "Copying M365 membership permissions based on entry..."

# Copy source user's O365 groups to new user
# Get the source user's groups, excluding dynamic groups
$sourceId = (Get-MgUser -UserId $SourceUser.UserPrincipalName).Id
$userId = (Get-MgUser -UserId $ADUserParams.UserPrincipalName).Id
$sourceGroups = Get-MgUserMemberOf -UserId $sourceId | Where-Object { $_.AdditionalProperties['groupTypes'] -notcontains "DynamicMembership" }
foreach ($group in $sourceGroups) {
$groupId = $group.Id
    $onPremisesSyncEnabled = $group.AdditionalProperties['onPremisesSyncEnabled']

    if ($onPremisesSyncEnabled -eq $false) {
        try {
            New-MgGroupMember -GroupId $groupId -DirectoryObjectId $userId
            Write-Host "Added $SamAccountName to group $groupId" -ForegroundColor Green
        } catch {
            Write-Host "Failed to add $SamAccountName to group $groupId. Error: $_" -ForegroundColor Red
            Write-Host "Please verify group memberships and add any additionals as necessary" -ForegroundColor Yellow
        }
    }
}
Start-Sleep 5

Clear-Host

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

if ($copyGroups -eq 'N') {
# Notify admin of manually adding memberships
Write-Host "Not copying memberships and permissions. Remember to add them to the account manually." -ForegroundColor:Red
Start-Sleep 5

# Setting Broadcast Attribute for email
Set-ADUser -Server $ADServer -Identity $SamAccountName -Add @{extensionAttribute15="Broadcast"}

# Add user to Helpdesk Customers Group
$helpdeskgroup = "Helpdesk Customers"
Add-ADGroupMember -Identity $helpdeskgroup -Members $SamAccountName

# Connecting to a Powershell session in EXCHANGE_ONPREM_SERVER and create an Office365 mailbox link
$OnPremSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://EXCHANGE_ONPREM_SERVER/powershell -Authentication Kerberos
Import-PSSession $OnPremSession -DisableNameChecking -AllowClobber
Enable-RemoteMailbox -Identity $SamAccountName -RemoteRoutingAddress $ADUserParams.MSFTRemoteMB -DomainController $ADServer

# HYBRID_SYNC_SERVER Delta Sync
Invoke-Command -ComputerName HYBRID_SYNC_SERVER -ScriptBlock { Start-ADSyncSyncCycle -PolicyType delta }
Read-Host -Prompt "Press Enter to sync On-Prem with O365"
Clear-Host
Write-Host "Please wait 60 seconds while On-Prem and O365 sync"
Start-Sleep 60
Clear-Host
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

Write-Host "Adding $($ADUserParams.Name) to MFA requirement"

# Add user to MFA Group on O365
$userId = (Get-MgUser -UserId $ADUserParams.UserPrincipalName).Id
$MFAgroup = Get-MgGroup -filter "DisplayName eq 'MSFT MFA-Users'"
New-MgGroupMember -GroupId $MFAgroup.id -DirectoryObjectId $userId
Start-Sleep 3

# Change user's usage location to US
Update-MgUser -UserId $userId -UsageLocation US
Start-Sleep 5
Clear-Host

# Assign User a License
Write-Host "What license would you like to give $($ADUserParams.Name)?"
Write-Host "=============================================="
Write-Host "      '1' for an E1 Office License"
Write-Host "      '2' for an E3 Office License"
Write-Host "      '3' for Exchange Only License"
Write-Host "      'Q' for NO License"
Write-Host "=============================================="
$LicPrompt = Read-Host "Enter Choice"
switch ($LicPrompt) {
    '1' { $E1Sku = Get-MgSubscribedSku -All | Where-Object SkuPartNumber -eq 'STANDARDPACK'
    Set-MgUserLicense -UserId $ADUserParams.UserPrincipalName -AddLicenses @{SkuId = $E1Sku.SkuId} -RemoveLicenses @()
    }
    '2' { $E3Sku = Get-MgSubscribedSku -All | Where-Object SkuPartNumber -eq 'ENTERPRISEPACK'
    Set-MgUserLicense -UserId $ADUserParams.UserPrincipalName -AddLicenses @{SkuId = $E3Sku.SkuId} -RemoveLicenses @()
    }
    '3' { $EOSku = Get-MgSubscribedSku -All | Where-Object SkuPartNumber -eq 'EXCHANGESTANDARD'
    Set-MgUserLicense -UserId $ADUserParams.UserPrincipalName -AddLicenses @{SkuId = $EOSku.SkuId} -RemoveLicenses @()
    }
    'Q' { Write-Host "Applying NO License..." -ForegroundColor:Yellow }
  }

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

# Send onboarding email
$message = @"
<b>Welcome to [BUSINESS_NAME]!</b>
<br><br>
Here are a few quick items we'd like for you to be aware of:
<br><br>
<li> 
To open a ticket with IT, send an email to <a href="mailto:helpdesk@contoso.com">helpdesk@contoso.com </a>. Add a brief problem description in the subject and any other helpful details in the body of the email.  
</li><br>
<li> 
You can access your email while offsite by logging into Office.com using your logon credentials: <em>username</em>@contoso.com and your <em>password</em><br>
</li><br>
<li>
Most employees will have an email signature automatically created. Check with your supervisor or send an email to your personal email account to view.
</li><br>
<li>
NEVER share your password or leave it visible at your workstation. The IT department does not need and will not ask for your password.
</li><br>
<li>
Laptop users can access our network while offsite using the FortiClient VPN Client. See your supervisor for assistance. Use your same logon credentials to get connected; <em>username</em> and your <em>password</em>
</li><br>
<li>
If you have a desk , your voicemail PIN has been reset to be the same as your extension. Attached is a quick reference guide for common tasks.
</li><br>
<br><br>
<b>IT Department Team Members</b>
<br>
John Doe:&emsp;IT Director
<br>
John Doe:&emsp;Network Administrator
<br>
John Doe:&emsp;IT Systems Administrator
<br>
Jane Doe:&emsp;Communications/IT Specialist
<br><br>
John Doe 4:&emsp;IT Systems Technician
<br><br><br>
Best Regards,
<br>
[COMPANY NAME] IT Department
"@
$EMUsername = 'helpdesk@contoso.com'
$EMPassword = 'Pswd/AppPswd'
$Secpasswd = ConvertTo-SecureString $EMPassword -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ($EMUsername, $Secpasswd)
Send-MailMessage -From $EMUsername -To "$SamAccountName@$Domain" -Subject "Onboard Email - Hello!" -BodyAsHtml $message -Attachments "\\Share\Location\Onboard\CiscoUnity_Voicemail_UserGuide.pdf" -SmtpServer smtp.office365.com -Credential $mycreds -UseSsl -Port 587

# Send onboarding email to user's personal email
function Get-ConfirmedEmail {
    do {
        # Ask for personal email
        $Pemail = Read-Host -Prompt "Please enter the user's personal email"
        # Confirm the email
        $Pconfirm = Read-Host -Prompt "Is this the correct email? $Pemail [Y/N]"
    }
    while ($Pconfirm -ne 'Y') # Repeat until confirmed
    return $Pemail
}

# Main script block
do {
    $PersonalEmail = Read-Host -Prompt "Do you want to send the user sign-on information to their personal email? [Y/N]"
    switch ($PersonalEmail) {
        'Y' {
            # Get and confirm the email
            $confirmedEmail = Get-ConfirmedEmail
            # Sending email logic
            $PEMUsername = 'helpdesk@contoso.com'
            $PEMPassword = 'Pswd/AppPswd'
            $Pmessage = @"
<b>Welcome to [BUSINESS_NAME]!</b>
<br><br>
To activate your County email please visit outlook.office.com (we recommend that you do this on a PC or tablet) using your new email address and password.
<br><br>
$SamAccountName@$Domain
<br>
$Password
<br>
Upon signing in, you will be presented with a message stating you need to set up Multifactor Authentication (MFA). Please download the Microsoft Authenticator app (links below) and continue with the setup process. There is an attached gif to help you walk through this process.
<br><br>
Once completed, you should be prompted to change your password. Please complete this before your start date.  If you have any questions please contact us via email <a href="mailto:helpdesk@contoso.com">helpdesk@contoso.com </a>.
<br><br>
<a href="https://apps.apple.com/us/app/microsoft-authenticator/id983156458">Authenticator for Apple</a><br>
<a href="https://play.google.com/store/apps/details?id=com.azure.authenticator&hl=en_US&gl=US&pli=1">Authenticator for Android</a>
<br><br>
<br>
[COMPANY NAME] IT Department
"@
            $Secpasswd = ConvertTo-SecureString $PEMPassword -AsPlainText -Force
            $mycreds = New-Object System.Management.Automation.PSCredential ($PEMUsername, $Secpasswd)
            Send-MailMessage -From $PEMUsername -To $confirmedEmail -Subject "Onboard Email - Hello!" -BodyAsHtml $Pmessage -Attachments "\\Share\Location\Onboard\MFA_Setup.gif" -SmtpServer smtp.office365.com -Credential $mycreds -UseSsl -Port 587
            Write-Host "Email sent to $confirmedEmail"
        }
        'N' {
            Write-Host "Continuing without sending email."
        }
    }
}
while ($PersonalEmail -notmatch '^[YN]$') # Validate input to be either Y or N

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

# Cleans up scripts connections
Disconnect-MgGraph | Out-Null
Remove-PSSession $OnPremSession | Out-Null
Start-Sleep 2
Clear-Host

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

Write-Host "Allow 30 minutes for Microsoft / Office 365 to create the mailbox"
Start-Sleep 5
Clear-Host

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

# Final display of User's information
Write-Host "========================================================"
Write-Host "The account was created with the following properties:"
Write-Host
Write-Host "Display name:   $Name"
Write-Host "Logon name:     $SamAccountName"
Write-Host "Employee ID:    $EmpID"
Write-Host "Email:          $SamAccountName@$Domain"
Write-Host "Password:       $Password"
Write-Host
Write-Host "Please note: User will be prompted to change password"
Write-Host
Write-Host "========================================================"

Read-Host "Press Enter to Exit"
Exit