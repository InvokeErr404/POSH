## Bulk updates users' titles and managers. ##
## It assumes your SamAccountNames are first initial + lastname (ex. jdoe) 
<#
# ==========================
 THIS SCRIPT REQUIRES A CSV
 CSV uses headers: EmployeeName, Title, Manager
John Doe, IT Technician, Jane Doe
# ==========================
#>

Import-Module ActiveDirectory

# Path to your CSV
$csvPath = "C:\Temp\UserUpdates.csv"

# Import data
$users = Import-Csv -Path $csvPath

# Prepare results for WhatIf report
$report = @()

foreach ($u in $users) {
    # Expect CSV columns: EmployeeName, Title, Manager
    $empName = $u.EmployeeName.Trim()
    $title   = $u.Title.Trim()
    $manager = $u.Manager.Trim()

    # --- Parse employee name ---
    # Split into first and remaining (everything after first space)
    $empParts   = $empName -split '\s+', 2
    $empGiven   = $empParts[0]
    $empSurname = if ($empParts.Count -gt 1) { $empParts[1] } else { "" }

    # Remove common suffixes and punctuation from surname
    $empSurname = $empSurname -replace ",|\.|Jr|Sr|III|IV|V", ""
    $empSurname = $empSurname.Trim().Replace("'", "").Replace('"', "")

    # Build expected SAM: first initial + last name (lowercase)
    $samGuess = ("{0}{1}" -f $empGiven.Substring(0,1), $empSurname).ToLower()

    # Try to find the AD user
    $adUser = Get-ADUser -Filter "SamAccountName -eq '$samGuess'" -Properties Title, Manager -ErrorAction SilentlyContinue

    if (-not $adUser) {
        $report += [PSCustomObject]@{
            EmployeeName   = $empName
            SamAccountName = $samGuess
            Status         = "User Not Found"
            CurrentTitle   = ""
            NewTitle       = $title
            CurrentManager = ""
            NewManager     = $manager
        }
        continue
    }

    # --- Parse Manager Name ---
    $mgrParts   = $manager -split '\s+', 2
    $mgrGiven   = $mgrParts[0]
    $mgrSurname = if ($mgrParts.Count -gt 1) { $mgrParts[1] } else { "" }

    $mgrSurname = $mgrSurname -replace ",|\.|Jr|Sr|III|IV|V", ""
    $mgrSurname = $mgrSurname.Trim().Replace("'", "").Replace('"', "")

    # Find the manager (case-insensitive match, handles hyphens)
    $mgr = Get-ADUser -Filter { GivenName -eq $mgrGiven -and Surname -eq $mgrSurname } -ErrorAction SilentlyContinue

    # Build report entry
    $report += [PSCustomObject]@{
        EmployeeName   = $empName
        SamAccountName = $samGuess
        Status         = if ($mgr) { "Ready" } else { "Manager Not Found" }
        CurrentTitle   = $adUser.Title
        NewTitle       = $title
        CurrentManager = if ($adUser.Manager) { (Get-ADUser $adUser.Manager -Properties Name).Name } else { "" }
        NewManager     = $manager
    }

    ### COMMENT AND RUN WHATIF REPORT FIRST. UNCOMMENT AND COMMENT WHATIF REPORT TO APPLY CHANGES ###

     if ($adUser) {
         Set-ADUser -Identity $adUser.DistinguishedName -Title $title
         if ($mgr) {
             Set-ADUser -Identity $adUser.DistinguishedName -Manager $mgr.DistinguishedName
         }
     }
}

# Export WhatIf report
$report | Export-Csv "C:\Temp\UserUpdate-WhatIf.csv" -NoTypeInformation -Encoding UTF8
Write-Host "What-If report complete: C:\Temp\UserUpdate-WhatIf.csv"
