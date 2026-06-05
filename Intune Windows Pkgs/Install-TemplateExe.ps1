## powershell.exe -ExecutionPolicy Bypass -File .\exeThisScript.ps1      ##   Paste this value, replacing the file name, in the install step on Intune when configuring
## powershell.exe -ExecutionPolicy Bypass -File .\exeUninstallScript.ps1 ##   Paste this value, replacing the file name, in the uninstall step on Intune when configuring

# Add any argument flags in the $InstallerArgs variable for your app

$InstallerFilename = "REPLACE_ME.exe"
$Installer = Join-Path $PSScriptRoot $InstallerFilename
$InstallerArgs = "/quiet / norestart"

if (!(Test-Path $Installer)) {
    exit 1
}

$Process = Start-Process -FilePath $Installer -ArgumentList $InstallerArgs -Wait -PassThru -NoNewWindow
exit $Process.ExitCode