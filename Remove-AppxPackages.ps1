# List of AppxPackages to remove
$AppxPackages = @(
    "Clipchamp.Clipchamp",
    "DellInc.DellSupportAssistforPCs",
    "Microsoft.BingWeather",
    "Microsoft.BingSearch",
    "Microsoft.BingNews",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.Xbox.TCUI",
    "MSTeams",
    "MicrosoftWindows.Speech.pt-PT.1",
    "MicrosoftWindows.Speech.pt-BR.1",
    "MicrosoftWindows.Speech.it-IT.1",
    "MicrosoftCorporationII.MicrosoftFamily",
    "MSTeams",
    "Microsoft.OutlookForWindows",
    "MicrosoftWindows.Speech.en-NZ.1",
    "MicrosoftWindows.Speech.en-IN.1",
    "MicrosoftWindows.Speech.en-IE.1",
    "MicrosoftWindows.Speech.en-GB.1",
    "MicrosoftWindows.Speech.fr-FR.1",
    "MicrosoftWindows.Speech.en-CA.1",
    "MicrosoftWindows.Speech.en-AU.1",
    "MicrosoftWindows.Speech.de-DE.1",
    "MicrosoftWindows.Speech.da-DK.1",
    "MicrosoftWindows.Speech.fr-CA.1",
    "MicrosoftWindows.Speech.es-MX.1",
    "MicrosoftWindows.Speech.es-ES.1",
    "Microsoft.PowerAutomateDesktop"
)

$AppxProvisionedPackages = @(
    "MicrosoftWindows.Speech.da-DK.1",
    "MicrosoftWindows.Speech.de-DE.1",
    "MicrosoftWindows.Speech.en-AU.1",
    "MicrosoftWindows.Speech.en-CA.1",
    "MicrosoftWindows.Speech.en-GB.1",
    "MicrosoftWindows.Speech.en-IE.1",
    "MicrosoftWindows.Speech.en-IN.1",
    "MicrosoftWindows.Speech.en-NZ.1",
    "MicrosoftWindows.Speech.es-ES.1",
    "MicrosoftWindows.Speech.es-MX.1",
    "MicrosoftWindows.Speech.fr-CA.1",
    "MicrosoftWindows.Speech.fr-FR.1",
    "MicrosoftWindows.Speech.it-IT.1",
    "MicrosoftWindows.Speech.pt-BR.1",
    "MicrosoftWindows.Speech.pt-PT.1",
    "MSTeams",
    "MicrosoftCorporationII.MicrosoftFamily",
    "Clipchamp.Clipchamp",
    "DellInc.DellSupportAssistforPCs",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.BingNews",
    "Microsoft.BingSearch",
    "Microsoft.BingWeather",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay"
)

# Loop through the list and remove each AppxPackage for all users
foreach ($Package in $AppxPackages) {
    Write-Host "Removing $Package for all users..."

    # Remove for current user
    Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq $Package } | Remove-AppxPackage -AllUsers

}

foreach ($Package in $AppxProvisionedPackages) {
    Write-Host "Removing $Package for all users..."

    # Remove provisioned package (prevents new users from getting it)
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $Package } | Remove-AppxProvisionedPackage -Online

}

Write-Host "All specified AppxPackages have been removed."




































# Get all appx packages
# Get-AppxPackage -name "*" -allusers | select name

# Now blacklisted from removing
# ("Microsoft.XboxGameCallable.UI", "Windows.CBSPreview")

# Script to uninstall bloat on Windows (tested on Win11 only)
$apps2 = @(
"Microsoft.Xbox.TCUI",
"Microsoft.XboxApp",
"Microsoft.XboxGameOverlay",
"Microsoft.XboxGamingOverlay",
"Microsoft.XboxIdentityProvider",
"Microsoft.XboxSpeechToTextOverlay",
"Clipchamp.Clipchamp",
"Microsoft.Office.OneNote",
"Microsoft.SkypeApp",
"microsoft.windowscommunicationsapps",
"Microsoft.OutlookForWindows",
"Microsoft.People",
"Microsoft.PowerAutomateDesktop",
"Microsoft.MicrosoftOfficeHub",
"Microsoft.MicrosoftSolitaireCollection",
"Microsoft.GamingApp",
"Microsoft.GetHelp",
"Microsoft.BingNews",
"Microsoft.BingWeather",
"Microsoft.YourPhone",
"Disney.37853FC22B2CE",
"SpotifyAB.SpotifyMusic"
)

foreach ($app in $apps2)
{
    Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers
}


# List of AppxPackages to remove
$AppxPackages = @(
    "Clipchamp.Clipchamp",
    "DellInc.DellSupportAssistforPCs",
    "Microsoft.BingWeather",
    "Microsoft.BingSearch",
    "Microsoft.BingNews",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.Xbox.TCUI",
    "MSTeams",
    "MicrosoftWindows.Speech.pt-PT.1",
    "MicrosoftWindows.Speech.pt-BR.1",
    "MicrosoftWindows.Speech.it-IT.1",
    "MicrosoftCorporationII.MicrosoftFamily",
    "MSTeams",
    "Microsoft.OutlookForWindows",
    "MicrosoftWindows.Speech.en-NZ.1",
    "MicrosoftWindows.Speech.en-IN.1",
    "MicrosoftWindows.Speech.en-IE.1",
    "MicrosoftWindows.Speech.en-GB.1",
    "MicrosoftWindows.Speech.fr-FR.1",
    "MicrosoftWindows.Speech.en-CA.1",
    "MicrosoftWindows.Speech.en-AU.1",
    "MicrosoftWindows.Speech.de-DE.1",
    "MicrosoftWindows.Speech.da-DK.1",
    "MicrosoftWindows.Speech.fr-CA.1",
    "MicrosoftWindows.Speech.es-MX.1",
    "MicrosoftWindows.Speech.es-ES.1",
    "Microsoft.PowerAutomateDesktop"
)

$AppxProvisionedPackages = @(
    "MicrosoftWindows.Speech.da-DK.1",
    "MicrosoftWindows.Speech.de-DE.1",
    "MicrosoftWindows.Speech.en-AU.1",
    "MicrosoftWindows.Speech.en-CA.1",
    "MicrosoftWindows.Speech.en-GB.1",
    "MicrosoftWindows.Speech.en-IE.1",
    "MicrosoftWindows.Speech.en-IN.1",
    "MicrosoftWindows.Speech.en-NZ.1",
    "MicrosoftWindows.Speech.es-ES.1",
    "MicrosoftWindows.Speech.es-MX.1",
    "MicrosoftWindows.Speech.fr-CA.1",
    "MicrosoftWindows.Speech.fr-FR.1",
    "MicrosoftWindows.Speech.it-IT.1",
    "MicrosoftWindows.Speech.pt-BR.1",
    "MicrosoftWindows.Speech.pt-PT.1",
    "MSTeams",
    "MicrosoftCorporationII.MicrosoftFamily",
    "Clipchamp.Clipchamp",
    "DellInc.DellSupportAssistforPCs",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.BingNews",
    "Microsoft.BingSearch",
    "Microsoft.BingWeather",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay"
)

# Loop through the list and remove each AppxPackage for all users
foreach ($Package in $AppxPackages) {
    Write-Host "Removing $Package for all users..."

    # Remove for current user
    Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq $Package } | Remove-AppxPackage -AllUsers

}

foreach ($Package in $AppxProvisionedPackages) {
    Write-Host "Removing $Package for all users..."

    # Remove provisioned package (prevents new users from getting it)
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $Package } | Remove-AppxProvisionedPackage -Online

}

Write-Host "All specified AppxPackages have been removed."