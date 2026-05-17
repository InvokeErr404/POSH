<#
.SYNOPSIS
    Windows Debloat and Configuration Script
.DESCRIPTION
    This script removes unnecessary Windows features, disables telemetry, 
    cleans up the Start Menu, and uninstalls Dell OEM bloatware.

.NOTES
    Name: Debloat-PCFull
    Version: 2.3.5
    Author: InvokeErr404
    Date of last revision: 05/17/2026

.NOTES
    2.0  - Initial Release (Rework of original script)
#>

# Requires Admin privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run this script as an Administrator."
    break
}

Write-Host "Starting Windows Debloat..." -ForegroundColor Cyan

# ==============================================================================
# Registry Cleanup (Default User)
# ==============================================================================

# Suppress errors for reg.exe commands
$ErrorActionPreference = "SilentlyContinue"

# Remove specific Explorer Namespace and Content Delivery keys
REG DELETE "HKEY_USERS\defaultuser0\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f
REG DELETE "HKEY_USERS\defaultuser0\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions" /f
REG DELETE "HKEY_USERS\defaultuser0\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps" /f

# Hide Copilot, Task View, and disable Taskbar Chat/Widgets for default user
REG ADD "HKEY_USERS\defaultuser0\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v ShowCopilotButton /t REG_DWORD /d 0
REG ADD "HKEY_USERS\defaultuser0\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v ShowTaskViewButton /t REG_DWORD /d 0
REG ADD "HKEY_USERS\defaultuser0\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v TaskbarDa /t REG_DWORD /d 0
REG ADD "HKEY_USERS\defaultuser0\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v TaskbarMn /t REG_DWORD /d 0

# Restore error action
$ErrorActionPreference = "Continue"

# ==============================================================================
# Remove Unwanted App Handlers and Tasks
# ==============================================================================

# Array of specific registry keys linked to bloatware/background tasks
$KeysToRemove = @(
    # EclipseManager & ActiproSoftware / Office Hub
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y",
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe",
    "HKCR:\Extensions\ContractId\Windows.File\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
    "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y",
    "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
    "HKCR:\Extensions\ContractId\Windows.PreInstalledConfigTask\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe",
    "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
    "HKCR:\Extensions\ContractId\Windows.ShareTarget\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
)

# Iterate and safely remove keys
ForEach ($Key in $KeysToRemove) {
    if (Test-Path $Key) { Remove-Item $Key -Recurse -Force }
}

# ==============================================================================
# System-Wide Telemetry and Search Configuration
# ==============================================================================

# Helper function to easily set registry values, creating the path if it doesn't exist
Function Set-RegValue ($Path, $Name, $Value, $Type = "DWord") {
    if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
}

# Advertising, Cortana, Web Search
Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" 1
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "EnableDynamicContentInWSB" 0 # Disable search games

# Windows Feeds / News and Interests
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" "EnableFeeds" 0
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0

# Consumer Features and Wi-Fi Sense
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1
Set-RegValue "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" "Value" 0
Set-RegValue "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" "Value" 0
Set-RegValue "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" "AutoConnectAllowedOEM" 0

# Disable OOBE Screens (Privacy, Voice, EULA, Animation)
$OobePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE"
Set-RegValue $OobePath "DisablePrivacyExperience" 1
Set-RegValue $OobePath "DisableVoice" 1
Set-RegValue $OobePath "PrivacyConsentStatus" 1
Set-RegValue $OobePath "Protectyourpc" 3
Set-RegValue $OobePath "HideEULAPage" 1
Set-RegValue "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" "EnableFirstLogonAnimation" 1

# Remove 3D Objects from "My Computer"
$ObjPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
if (Test-Path "HKLM:\$ObjPath") { Remove-Item "HKLM:\$ObjPath" -Recurse -Force }
if (Test-Path "HKLM:\WOW6432Node\$ObjPath") { Remove-Item "HKLM:\WOW6432Node\$ObjPath" -Recurse -Force }

# Disable Unnecessary Scheduled Tasks
$TasksToDisable = @("XblGameSaveTaskLogon", "XblGameSaveTask", "Consolidator", "UsbCeip", "DmClient", "DmClientOnScenarioDownload")
ForEach ($Task in $TasksToDisable) {
    Get-ScheduledTask -TaskName $Task -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue
}

# ==============================================================================
# Default User Profile Tweaks (via loading C:\Users\Default\NTUser.dat as HKU\DefaultUser0)
# ==============================================================================

$DefaultUserHivePath = "C:\Users\Default\NTUSER.DAT"
reg load "HKU\DefaultUser0" $DefaultUserHivePath | Out-Null

# Disable Bing Search & Feedback Experience Data
Set-RegValue "Registry::HKEY_USERS\defaultuser0\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
Set-RegValue "Registry::HKEY_USERS\defaultuser0\Software\Microsoft\Siuf\Rules" "PeriodInNanoSeconds" 0

# Stop Pre-installed OEM Apps and Content Delivery
$ContentMgr = "Registry::HKEY_USERS\defaultuser0\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
Set-RegValue $ContentMgr "ContentDeliveryAllowed" 0
Set-RegValue $ContentMgr "OemPreInstalledAppsEnabled" 0
Set-RegValue $ContentMgr "PreInstalledAppsEnabled" 0
Set-RegValue $ContentMgr "PreInstalledAppsEverEnabled" 0
Set-RegValue $ContentMgr "SilentInstalledAppsEnabled" 0
Set-RegValue $ContentMgr "SystemPaneSuggestionsEnabled" 0
Set-RegValue $ContentMgr "RotatingLockScreenOverlayEnabled" 0 # Spotlight off
Set-RegValue $ContentMgr "RotatingLockScreenEnabled" 0        # Spotlight off

# Holographic First Run & Live Tiles
Set-RegValue "Registry::HKEY_USERS\defaultuser0\Software\Microsoft\Windows\CurrentVersion\Holographic" "FirstRunSucceeded" 0
Set-RegValue "Registry::HKEY_USERS\defaultuser0\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" "NoTileApplicationNotification" 1

# Desktop/Taskbar visual cleanups (People Band, Learn about this picture, Spotlight Desktop)
Set-RegValue "Registry::HKEY_USERS\defaultuser0\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" "PeopleBand" 0
Set-RegValue "Registry::HKEY_USERS\defaultuser0\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" 1
Set-RegValue "Registry::HKEY_USERS\defaultuser0\Software\Policies\Microsoft\Windows\CloudContent" "DisableSpotlightCollectionOnDesktop" 1
Set-RegValue "Registry::HKEY_USERS\defaultuser0\Software\Policies\Microsoft\Windows\CloudContent" "DisableWindowsSpotlightFeatures" 1

# Unload Default User Profile
reg unload "HKU\DefaultUser0" | Out-Null

# ==============================================================================
# Start Layout Modification
# ==============================================================================

# Write a blank start layout XML template
$XmlPath = "C:\Windows\StartLayout.xml"
@"
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
 <LayoutOptions StartTileGroupCellWidth="6" />
 <DefaultLayoutOverride>
 <StartLayoutCollection>
 <defaultlayout:StartLayout GroupCellWidth="6" />
 </StartLayoutCollection>
 </DefaultLayoutOverride>
</LayoutModificationTemplate>
"@ | Out-File $XmlPath -Encoding UTF8 -Force

# Windows 11 Start Menu Cleanup
$OsVersion = (Get-CimInstance Win32_OperatingSystem).Caption
if ($OsVersion -like "*Windows 11*") {
    $Win11LayoutPath = "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml"
    if (Test-Path $Win11LayoutPath) { Remove-Item $Win11LayoutPath -Force }

    $BlankJson = @'
{
    "pinnedList": [
        { "desktopAppId": "MSEdge" },
        { "packagedAppId": "Microsoft.WindowsStore_8wekyb3d8bbwe!App" },
        { "desktopAppId": "Microsoft.Windows.Explorer" }
    ]
}
'@
    $BlankJson | Out-File $Win11LayoutPath -Encoding UTF8 -Force

    # Download debloated bin file if a non-admin user exists
    $Profiles = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | ForEach-Object { Get-ItemProperty $_.PSPath }
    $NonAdminLoggedOn = ($Profiles | Where-Object { $_.PSChildName -notmatch '^(\.DEFAULT|S-1-5-1[89]|S-1-5-20|S-1-5-21-\d+-\d+-\d+-500)$' }).Count -gt 0

    if ($NonAdminLoggedOn) {
        $LocalStateDir = "C:\Users\Default\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"
        New-Item -ItemType Directory -Force -Path $LocalStateDir -ErrorAction SilentlyContinue | Out-Null
        Invoke-WebRequest -Uri "https://github.com/andrew-s-taylor/public/raw/main/De-Bloat/start2.bin" -OutFile "$LocalStateDir\Start2.bin"
    }
}

# ==============================================================================
# Dell AppX and Program Cleanup
# ==============================================================================

# Note: The original script called 'UninstallAppFull' which is not native to PS. 
# Assuming it is an imported function in your environment.

$AppsToIgnore = @() # Define to prevent null errors
$DellPrograms = @(
    "Dell Optimizer", "Dell Power Manager", "DellOptimizerUI", "Dell SupportAssist OS Recovery",
    "Dell SupportAssist", "Dell Optimizer Service", "Dell Optimizer Core", "DellInc.PartnerPromo",
    "DellInc.DellOptimizer", "DellInc.DellCommandUpdate", "DellInc.DellPowerManager",
    "DellInc.DellDigitalDelivery", "DellInc.DellSupportAssistforPCs", "Dell Command | Update",
    "Dell Command | Update for Windows Universal", "Dell Command | Update for Windows 10",
    "Dell Command | Power Manager", "Dell Digital Delivery Service", "Dell Digital Delivery",
    "Dell Peripheral Manager", "Dell Power Manager Service", "Dell SupportAssist Remediation",
    "SupportAssist Recovery Assistant", "Dell SupportAssist OS Recovery Plugin for Dell Update",
    "Dell SupportAssistAgent", "Dell Update - SupportAssist Update Plugin", "Dell Core Services",
    "Dell Pair", "Dell Display Manager 2.0", "Dell Display Manager 2.1", "Dell Display Manager 2.2"
) | Where-Object { $_ -notin $AppsToIgnore } | Select-Object -Unique

# Remove Appx Packages
foreach ($App in $DellPrograms) {
    if (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*$App*") {
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*$App*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
    if (Get-AppxPackage -AllUsers -Name "*$App*") {
        Get-AppxPackage -AllUsers -Name "*$App*" | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    }
    
    # Try calling custom function if it exists
    if (Get-Command UninstallAppFull -ErrorAction SilentlyContinue) {
        UninstallAppFull -appName $App
    }
    
    # WMI/CIM Cleanup
    Get-CimInstance -Query "SELECT * FROM Win32_Product WHERE Name = '$App'" | Invoke-CimMethod -MethodName Uninstall -ErrorAction SilentlyContinue
}

# Execute Silent Uninstalls from Registry Strings
$UninstallKeysPath = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$TargetApps = @("Dell*Optimizer*", "Dell SupportAssist Remediation")
ForEach ($Target in $TargetApps) {
    $UninstallStrings = Get-ItemProperty $UninstallKeysPath -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like $Target } | Select-Object -ExpandProperty UninstallString -ErrorAction SilentlyContinue
    ForEach ($String in $UninstallStrings) {
        if ($String) { cmd.exe /c "$String /quiet /norestart /qn" }
    }
}

# Direct Executable Uninstalls for specific Dell Paths
$DirectUninstalls = @(
    "C:\Program Files\Dell\Dell Peripheral Manager\Uninstall.exe",
    "C:\Program Files\Dell\Dell Display Manager 2.0\uninst.exe",
    "C:\Program Files\Dell\Dell Pair\Uninstall.exe"
)

ForEach ($Exe in $DirectUninstalls) {
    if (Test-Path $Exe) { cmd /c "`"$Exe`" /S" }
}

$InstallShieldPaths = @(
    "C:\Program Files (x86)\InstallShield Installation Information\{286A9ADE-A581-43E8-AA85-6F5D58C7DC88}\DellOptimizer.exe /remove /silent",
    "C:\Program Files (x86)\InstallShield Installation Information\{2F3E37A4-8F48-465A-813B-1F2964DBEB6A}\setup.exe /s /uninst"
)
ForEach ($CmdStr in $InstallShieldPaths) {
    $Path = $CmdStr.Split(" ")[0]
    if (Test-Path $Path) { cmd /c "`"$CmdStr`"" }
}

$PackageCachePaths = @(
    "C:\ProgramData\Package Cache\{cff56899-3afb-4fe1-aeec-a0474836d1cd}\DellUpdateSupportAssistPlugin.exe /uninstall /quiet",
    "C:\ProgramData\Package Cache\{ab3f7261-beee-49b8-b31a-27dd1dfd122d}\DellUpdateSupportAssistPlugin.exe /uninstall /quiet"
)
ForEach ($CmdStr in $PackageCachePaths) {
    $Path = $CmdStr.Split(" ")[0]
    if (Test-Path $Path) { cmd /c "`"$CmdStr`"" }
}

Write-Host "Debloat Complete." -ForegroundColor Green
