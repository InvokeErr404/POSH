# ---------------- CONFIGURATION ----------------
$vppAppId = "de70e331-110c-470a-8119-57d492919d73"           # iOS VPP App in Intune
$userGroupId = "GroupGUIDFromEntra"        # Group with user members

# Connect to Graph
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All"
}
Select-MgProfile -Name beta

# ​​​ Remove all existing assignments
$existing = Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $vppAppId -ErrorAction SilentlyContinue
if ($existing) {
    foreach ($assign in $existing) {
        Write-Host "Removing assignment id: $($assign.Id)"
        Remove-MgDeviceAppManagementMobileAppAssignment `
            -MobileAppId $vppAppId `
            -MobileAppAssignmentId $assign.Id `
            -ErrorAction Stop
    }
}

# ​​​ Add new "Available" assignment using USER licensing
$assignmentBody = @{
    "@odata.type" = "#microsoft.graph.mobileAppAssignment"
    target = @{
        "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
        groupId       = $userGroupId
    }
    intent = "available"
    settings = @{
        "@odata.type" = "#microsoft.graph.iosVppAppAssignmentSettings"
        useDeviceLicensing = $false
    }
}

# POST to Graph
Invoke-MgGraphRequest -Method POST `
    -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$vppAppId/assignments" `
    -Body ($assignmentBody | ConvertTo-Json -Depth 5 -Compress)

Write-Host "Successfully re-assigned VPP app as 'Available' with USER license."
