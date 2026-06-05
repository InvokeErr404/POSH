$ProductCode = "{REPLACE-ME}"   # include the { } , you can usuall find in registry at locations listed below if system wide install

$Installed = Get-ItemProperty `
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" ,
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -eq $ProductCode }

if (!$Installed) {
    exit 0
}

$Process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $ProductCode /qn /norestart" -Wait -PassThru -NoNewWindow
exit $Process.ExitCode