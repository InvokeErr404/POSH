## Have not tested this...good luck ##

$UninstallExe  = "REPLACE_ME"   # likely located in the install dir. You can find uninstall pkg location in registry
$UninstallArgs = "REPLACE_ME"

if (!(Test-Path $UninstallExe)) {
    exit 0
}

$Process = Start-Process -FilePath $UninstallExe -ArgumentList $UninstallArgs -Wait -PassThru -NoNewWindow
exit $Process.ExitCode
