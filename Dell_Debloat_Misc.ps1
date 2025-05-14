# Support Assist and Support Assit OS Plugin
$SAVer = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall  |
    Get-ItemProperty |
        Where-Object {$_.DisplayName -match "Dell SupportAssist Remediation" } |
            Select-Object -Property DisplayVersion, UninstallString, PSChildName

ForEach ($ver in $SAVer) {

    If ($ver.UninstallString) {

        $uninst = $ver.UninstallString
        & cmd /c $uninst /quiet /norestart

    }
}

# Dell Optimizer
$TestDO = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Dell Optimizer"
if ($TestDO -eq $true) {
$SAVer = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall  |
    Get-ItemProperty |
        Where-Object {$_.DisplayName -match "Dell Optimizer" } | 
            Select-Object -Property DisplayVersion, UninstallString, PSChildName

ForEach ($ver in $SAVer) {

    If ($ver.UninstallString) {

        $uninst = $ver.UninstallString
        & cmd /c $uninst /quiet /qn

    }
}
}

# Dell Peripheral Manager
$TestDPM = Test-Path "C:\Program Files\Dell\Dell Peripheral Manager\"
if ($TestDPM -eq $true) {
cmd /c '"C:\Program Files\Dell\Dell Peripheral Manager\Uninstall.exe" /S'
}

# Dell Display Manager 2.0
$TestDDM = Test-Path "C:\Program Files\Dell\Dell Display Manager 2.0\"
if ($TestDDM -eq $true) {
cmd /c '"C:\Program Files\Dell\Dell Display Manager 2.0\uninst.exe" /S'
}

# Dell Optimizer Service
$TestDOS = Test-Path "C:\Program Files (x86)\InstallShield Installation Information\{286A9ADE-A581-43E8-AA85-6F5D58C7DC88}"
if ($TestDOS -eq $true) {
cmd /c '"C:\Program Files (x86)\InstallShield Installation Information\{286A9ADE-A581-43E8-AA85-6F5D58C7DC88}\DellOptimizer.exe" /remove /silent'
}

# Dell Support Assist
$TestDAS = Test-Path "C:\ProgramData\Package Cache\{cff56899-3afb-4fe1-aeec-a0474836d1cd}"
$TestDAS2 = Test-Path "C:\ProgramData\Package Cache\{ab3f7261-beee-49b8-b31a-27dd1dfd122d}"
if ($TestDAS -eq $true) {
cmd /c '"C:\ProgramData\Package Cache\{cff56899-3afb-4fe1-aeec-a0474836d1cd}\DellUpdateSupportAssistPlugin.exe" /uninstall /quiet'
}
if ($TestDAS2 -eq $true) {
cmd /c '"C:\ProgramData\Package Cache\{ab3f7261-beee-49b8-b31a-27dd1dfd122d}\DellUpdateSupportAssistPlugin.exe" /uninstall /quiet'
}

# Dell Watchdog Timer
$TestWDT = Test-Path "C:\Program Files (x86)\InstallShield Installation Information\{2F3E37A4-8F48-465A-813B-1F2964DBEB6A}"
if ($TestWDT -eq $true) {
cmd /c '"C:\Program Files (x86)\InstallShield Installation Information\{2F3E37A4-8F48-465A-813B-1F2964DBEB6A}\setup.exe" /s /uninst'
}