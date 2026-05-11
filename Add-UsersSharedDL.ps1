<#
# ==========================
 THIS SCRIPT REQUIRES A CSV
 CSV uses header: UserEmail
 user1@domain.com
 user2@domain.com
 user3@domain.com

# ==========================
#>

$SharedMB = "smbx@contoso.com"
$DistroL  = "distro@contoso.com"
$CsvPath  = "C:\Temp\UsersToAdd.csv"


# Connect to Exchange Online
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline

# Import users from csv
$Users = Import-Csv $CsvPath

# Process list of users
foreach ($User in $Users) {

    $Email = $User.UserEmail

    # Add to Shared Mailbox (Full Access)
    try {
        Add-MailboxPermission `
            -Identity $SharedMB `
            -User $Email `
            -AccessRights FullAccess `
            -InheritanceType All `
            -AutoMapping $true `
            -ErrorAction Stop

        Write-Host "Shared mailbox access granted to $Email"
    }
    catch {
        Write-Warning "Shared mailbox failed for $Email : $_"
    }

    # Add to Distribution List
    try {
        Add-DistributionGroupMember `
            -Identity $DistroL `
            -Member $Email `
            -ErrorAction Stop

        Write-Host "Distribution list membership added for $Email"
    }
    catch {
        Write-Warning "Distribution list failed for $Email : $_"
    }
}

Disconnect-ExchangeOnline -Confirm:$false