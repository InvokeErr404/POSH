## Installs all fonts in share location...because that was required at this job at time of upload ##
## Kind of janky, I wouldn't use. ##

$LogFile = "C:\Windows\posh_font_install.log"
$SourceFolder = "\\contoso.local\SYSVOL\contoso.local\scripts\Fonts"
$FontsFolder = "$env:SystemRoot\Fonts"
$FontsRegKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

function Write-Log {
    param ([string]$Message)
    $Stamp = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "$Stamp $Message"
}

Get-ChildItem -Path $SourceFolder -Include *.ttf, *.otf -Recurse -File | ForEach-Object {

    $FontFile = $_.Name
    $DestPath = Join-Path $FontsFolder $FontFile

if (-not (Test-Path $DestPath)) {
    Copy-Item $_.FullName $DestPath
    Write-Log "Copied font file $FontFile"
}
else {
    Write-Log "Font file already exists: $FontFile"
}

    Write-Log "Copied font file $FontFile"

    # Determine font type
    switch ($_.Extension.ToLower()) {
        ".ttf" { $FontType = "TrueType" }
        ".otf" { $FontType = "OpenType" }
        default { return }
    }

    # Registry value name MUST include font type
    $RegValueName = "$($FontFile) ($FontType)"

    if (-not (Get-ItemProperty -Path $FontsRegKey -Name $RegValueName -ErrorAction SilentlyContinue)) {
        New-ItemProperty `
            -Path $FontsRegKey `
            -Name $RegValueName `
            -Value $FontFile `
            -PropertyType String `
            -Force | Out-Null

        Write-Log "Registered font $RegValueName"
    }
    else {
        Write-Log "Font already registered: $RegValueName"
    }
}
