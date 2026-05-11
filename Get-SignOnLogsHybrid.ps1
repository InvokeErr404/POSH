## Get sign on logs for hybrid users. This WILL take some time depending on your cutoff date ##

# Enter cutoff date for stale users
$cutoff = Get-Date "2025-05-01"
$csvPath = "C:\temp\HybridStaleUsers.csv"
$ou = "OU=Users,DC=contoso,DC=local"

# Connect to Microsoft Graph
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "AuditLog.Read.All", "User.Read.All", "Directory.Read.All"
}

# Get Enabled AD Users in Specific OU with stale/no logon
$adUsers = Get-ADUser -SearchBase $ou -Filter {Enabled -eq $true} -Properties DisplayName, LastLogonDate, UserPrincipalName |
    Where-Object { -not $_.LastLogonDate -or $_.LastLogonDate -le $cutoff }

# Loop through users
$results = foreach ($user in $adUsers) {
    $upn = $user.UserPrincipalName
    $azureLastSignIn = "NONE"
    $lastInteractive = "NONE"
    $lastNonInteractive = "NONE"

    if (-not $upn) {
        Write-Host "Skipping user with missing UPN: $($user.SamAccountName)"
        continue
    }

    try {
    $upn = $upn.Trim().ToLower()
    $Properties = @('DisplayName','UserPrincipalName','SignInActivity')
    $mgUser = Get-MgUser -Filter "userPrincipalName eq '$upn'" -Property $Properties -ErrorAction Stop

    if (-not $mgUser) {
        Write-Warning "No matching Azure user for UPN: $upn"
        continue
    }

    # Use SignInActivity for last interactive/non-interactive logins
    if ($mgUser.SignInActivity) {
        if ($mgUser.SignInActivity.LastInteractiveSignInDateTime -and $mgUser.SignInActivity.LastInteractiveSignInDateTime -le $cutoff) {
            $lastInteractive = $mgUser.SignInActivity.LastInteractiveSignInDateTime.ToString("yyyy-MM-dd")
        }

        if ($mgUser.SignInActivity.LastNonInteractiveSignInDateTime -and $mgUser.SignInActivity.LastNonInteractiveSignInDateTime -le $cutoff) {
            $lastNonInteractive = $mgUser.SignInActivity.LastNonInteractiveSignInDateTime.ToString("yyyy-MM-dd")
        }
    }

    # Optional: sign-in logs
    $signIns = Get-MgAuditLogSignIn -Filter "userId eq '$($mgUser.Id)'" -Top 50 |
        Where-Object {
            $_.CreatedDateTime -le $cutoff -and
            ($_.SignInEventTypes -contains "interactive" -or $_.SignInEventTypes -contains "nonInteractive")
        } |
        Sort-Object CreatedDateTime -Descending

    if ($signIns) {
        $azureLastSignIn = $signIns[0].CreatedDateTime.ToString("yyyy-MM-dd")
    } else {
        Write-Host "No Azure sign-ins found for $upn before or on $($cutoff.ToShortDateString())."
    }
}
catch {
    Write-Warning "Azure user not found or error for: $upn. Skipping..."
    continue
}

    [PSCustomObject]@{
        SamAccountName            = $user.SamAccountName
        DisplayName               = $user.DisplayName
        OnPremLastLogon           = if ($user.LastLogonDate) { $user.LastLogonDate.ToString("yyyy-MM-dd") } else { "Never" }
        AzureLastSignIn           = $azureLastSignIn
        LastInteractiveSignIn     = $lastInteractive
        LastNonInteractiveSignIn  = $lastNonInteractive
    }
}

# Export results
$results | Export-Csv $csvPath -NoTypeInformation
Write-Host "CSV report saved to: $csvPath"
