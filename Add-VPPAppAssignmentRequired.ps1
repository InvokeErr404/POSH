# ---------------- CONFIG ----------------
# List of VPP App IDs from Intune
$vppAppIds = @(
    "6b61f5f9-0aac-4305-a0db-0b67d834847a",
    "e3e5d8cc-290f-4293-9c6a-5d231f837e0c",
    "8f18b935-14ab-4820-975c-0bdc3593e0bf",
    "64961e8a-2832-4274-9d2a-e7f02a6af031",
    "59be8911-a6c9-4d5f-8891-31e3a3d6341a"
)

# Assignments config
$groupId = "GroupGUIDFromEntra"   # Group to assign the apps to
$intent = "required"             # Options: "required", "available", "uninstall"
$installIntent = "required"
$vppTokenAssignmentType = "user" # Ensure User licensing

# ---------------- LOGIN ----------------
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All"
Select-MgProfile -Name beta

foreach ($appId in $vppAppIds) {
    Write-Host "Processing VPP App: $appId"

    # 1️⃣ Remove all existing assignments
    $assignments = Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $appId -ErrorAction SilentlyContinue
    foreach ($assignment in $assignments) {
        Remove-MgDeviceAppManagementMobileAppAssignment -MobileAppId $appId -MobileAppAssignmentId $assignment.Id -ErrorAction SilentlyContinue
        Write-Host "Removed assignment $($assignment.Id) from app $appId"
    }

    # 2️⃣ Add required assignment with User license
    $params = @{
        "@odata.type" = "#microsoft.graph.mobileAppAssignment"
        intent = $intent
        target = @{
            "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
            groupId = $groupId
        }
        settings = @{
            "@odata.type" = "#microsoft.graph.iosVppAppAssignmentSettings"
            useDeviceLicensing = $false  # False = User license, True = Device license
        }
    }

    New-MgDeviceAppManagementMobileAppAssignment -MobileAppId $appId -BodyParameter $params
    Write-Host "Added REQUIRED User license assignment for app $appId"
}

Write-Host "Successfully re-assigned VPP app as 'Required' with USER license."
