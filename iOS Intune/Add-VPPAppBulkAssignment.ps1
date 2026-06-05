## Device Licensing I've seen work best (results may vary) ##

# ---------------- CONFIG ----------------
# List of VPP App IDs to leave untouched
$excludeAppIds = @(
    "6b61f5f9-0aac-4305-a0db-0b67d834847a",
    "e3e5d8cc-290f-4293-9c6a-5d231f837e0c",
    "8f18b935-14ab-4820-975c-0bdc3593e0bf",
    "64961e8a-2832-4274-9d2a-e7f02a6af031",
    "99cd2f22-42f4-41f7-9a78-1074a283d1b3",
    "dfc2f470-0b66-4247-8191-9393dce78580",
    "59be8911-a6c9-4d5f-8891-31e3a3d6341a"
)

# Group to assign updated apps to
$groupId = "GroupGUIDFromEntra"  # Get with: Get-MgGroup -Search "Group Name"

# ---------------- LOGIN ----------------
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All"
Select-MgProfile -Name beta

# 1️⃣ Get all mobile apps in Intune
$allApps = Get-MgDeviceAppManagementMobileApp -All

foreach ($app in $allApps) {
    # Skip the excluded apps
    if ($excludeAppIds -contains $app.Id) {
        Write-Host "`nSkipping protected app: $($app.DisplayName) [$($app.Id)]"
        continue
    }

    Write-Host "`nProcessing App: $($app.DisplayName) [$($app.Id)]"

    # 2️⃣ Get current assignments for this app
    $assignments = Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id -ErrorAction SilentlyContinue

    # Remove all assignments
    foreach ($assignment in $assignments) {
        Remove-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id -MobileAppAssignmentId $assignment.Id -ErrorAction SilentlyContinue
        Write-Host "  Removed assignment $($assignment.Id)"
    }

    # 3️⃣ Assign as AVAILABLE with user license
    $params = @{
        "@odata.type" = "#microsoft.graph.mobileAppAssignment"
        intent = "available"
        target = @{
            "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
            groupId = $groupId
        }
        settings = @{
            "@odata.type" = "#microsoft.graph.iosVppAppAssignmentSettings"
            useDeviceLicensing = $false # false = User license
        }
    }

    New-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id -BodyParameter $params
    Write-Host "Assigned as AVAILABLE (User license)"
}

Write-Host "Finished updating apps."
