# Replace with the Subject or Thumbprint of the old root cert
$oldRootSubject = "e2df9f0352a964a699f27250ab341c64ea558976"

# Search LocalMachine personal store for certs chaining to that root
Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {
    $_.Issuer -like "*$oldRootSubject*"
} | Select-Object Subject, NotAfter, Thumbprint

# Replace with the Subject Name (CN) or part of it of your old root cert
$oldRootSubjectPart = "DC1.contoso.local"

# Stores to check — add or remove as needed
$stores = @(
    "Cert:\LocalMachine\My",
    "Cert:\LocalMachine\WebHosting",
    "Cert:\LocalMachine\Remote Desktop",
    "Cert:\LocalMachine\AuthRoot",
    "Cert:\LocalMachine\Root",
    "Cert:\LocalMachine\CA",
    "Cert:\CurrentUser\My",
    "Cert:\CurrentUser\Root",
    "Cert:\CurrentUser\CA"
)

$foundCerts = @()

foreach ($store in $stores) {
    Write-Host "Checking store: $store"
    try {
        $certs = Get-ChildItem -Path $store -ErrorAction Stop
        foreach ($cert in $certs) {
            # Check if Issuer contains old root cert subject name
            if ($cert.Issuer -like "*$oldRootSubjectPart*") {
                $foundCerts += [PSCustomObject]@{
                    Store       = $store
                    Subject     = $cert.Subject
                    Issuer      = $cert.Issuer
                    Thumbprint  = $cert.Thumbprint
                    NotAfter    = $cert.NotAfter
                }
            }
        }
    }
    catch {
        Write-Warning "Cannot access store: $store - $_"
    }
}

if ($foundCerts.Count -eq 0) {
    Write-Host "No certificates found issued by root matching '$oldRootSubjectPart'."
} else {
    Write-Host "Found certificates issued by root matching '$oldRootSubjectPart':"
    $foundCerts | Format-Table -AutoSize
}