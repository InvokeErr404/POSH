## This takes a csv list of machines that I'v extracted from Entra to audit if they are active or even exist in AD ##
## Can't remember csv format/headers...oops ##

# Import machine names from CSV
$machines = Import-Csv -Path "C:\temp\MachineNames.csv"

# Get all domain-joined computers with last logon info
$domainMachines = Get-ADComputer -Filter * -Properties Name, LastLogonTimestamp | 
    Select-Object Name, LastLogonTimestamp

# Set time threshold (e.g., 60 days ago)
$staleThreshold = (Get-Date).AddDays(-60)

# Result buckets
$inDomainActive = @()
$inDomainStale = @()
$notInDomain = @()

# Process each machine from the CSV
foreach ($entry in $machines) {
    $name = $entry.MachineName.Trim()

    $match = $domainMachines | Where-Object { $_.Name -ieq $name }

    if ($match) {
        # Convert LastLogonTimestamp to DateTime if it's populated
        if ($match.LastLogonTimestamp) {
            $lastLogon = [DateTime]::FromFileTime($match.LastLogonTimestamp)
        } else {
            $lastLogon = $null
        }

        if ($lastLogon -and $lastLogon -lt $staleThreshold) {
            $inDomainStale += [PSCustomObject]@{ Name = $name; LastLogon = $lastLogon }
        } else {
            $inDomainActive += [PSCustomObject]@{ Name = $name; LastLogon = $lastLogon }
        }
    } else {
        $notInDomain += $name
    }
}

# Output Results
Write-Host "In Domain and Active (seen within 60 days):"
$inDomainActive | Sort-Object Name | Format-Table -AutoSize

Write-Host "In Domain but Stale (NOT seen in 60+ days):"
$inDomainStale | Sort-Object Name | Format-Table -AutoSize

Write-Host "NOT in Domain:"
$notInDomain | Sort-Object | ForEach-Object { Write-Host $_ }
 