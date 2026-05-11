<#
# ==========================
 THIS SCRIPT REQUIRES A CSV
 CSV uses header: Id
 user1@domain.com
 user2@domain.com
 user3@domain.com

# ==========================
#>


Connect-MgGraph -Scopes "Group.ReadWrite.All"

# Target group ID where you want to add members
$targetGroupId = "ID GUID of Group from Entra"

# Import CSV (Export list of users from Entra. Needs column "Id")
$users = Import-Csv -Path "C:\Temp\GroupMembers.csv"

# What-If report logic
<#
$report = foreach ($u in $users) {
    try {
        # Check if user already exists in the target group
        $existing = Get-MgGroupMember -GroupId $targetGroupId -All | Where-Object { $_.Id -eq $u.Id }

        if ($existing) {
            [PSCustomObject]@{
                UserId = $u.Id
                Action = "Already in group"
            }
        }
        else {
            [PSCustomObject]@{
                UserId = $u.Id
                Action = "Would be added"
            }
        }
    }
    catch {
        [PSCustomObject]@{
            UserId = $u.Id
            Action = "Error: $($_.Exception.Message)"
        }
    }
}


# Create What-If report (uncomment lines 37-38, comment lines 40-54)
# Make it a prompt if report first then apply (yes/no to both)

$report | Export-Csv -Path "C:\Temp\WhatIf-GroupAdd.csv" -NoTypeInformation
Write-Host "What-If report saved to C:\Temp\WhatIf-GroupAdd.csv"
#>

# Add users to group
foreach ($u in $users) {
    try {
        New-MgGroupMember -GroupId $targetGroupId -DirectoryObjectId $u.Id -ErrorAction Stop
        Write-Host "Added $($u.Id) to group."
    }
    catch {
        if ($_.Exception.Message -like "*added object references already exist*") {
            Write-Host "User $($u.Id) already in group, skipping."
        }
        else {
            Write-Warning "Failed to add $($u.Id): $_"
        }
    }
}