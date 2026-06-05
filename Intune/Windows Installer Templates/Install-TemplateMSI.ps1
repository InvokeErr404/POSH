## powershell.exe -ExecutionPolicy Bypass -File .\msiThisScript.ps1      ##   Paste this value, replacing the file name, in the install step on Intune when configuring
## powershell.exe -ExecutionPolicy Bypass -File .\msiUninstallScript.ps1 ##   Paste this value, replacing the file name, in the uninstall step on Intune when configuring

# Add any argument flags in the $Process variable for your app

$InstallerFilename = "REPLACE_ME.msi"
$Installer = Join-Path $PSScriptRoot $InstallerFilename

if (!(Test-Path $Installer)) {
    exit 1
}

$Process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$Installer`" /qn /norestart" -Wait -PassThru -NoNewWindow
exit $Process.ExitCode