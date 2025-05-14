
# Note: This script requires administrative privileges to run
# It will search for and uninstall OneDrive from any versioned directories under the specified paths
# Define the base paths
$paths = @("C:\Program Files", "C:\Program Files (x86)")

# Define the partial path and executable name
$partialPath = "Microsoft OneDrive"
$executableName = "OneDriveSetup.exe"

foreach ($path in $paths) {
    # Construct the search path
    $searchPath = Join-Path -Path $path -ChildPath $partialPath

    # Check if the search path exists
    if (Test-Path $searchPath) {
        # Find all instances of OneDriveSetup.exe under the versioned folders
        $files = Get-ChildItem -Path $searchPath -Filter $executableName -Recurse -ErrorAction SilentlyContinue

        foreach ($file in $files) {
            try {
                # Execute the uninstall command
                Start-Process $file.FullName -ArgumentList "/uninstall /allusers /force" -Wait -NoNewWindow
                Write-Host "Uninstalled OneDrive from: $($file.FullName)"
            } catch {
                Write-Host "Failed to uninstall OneDrive from: $($file.FullName). Error: $_"
            }
        }
    }
    else {
        Write-Host "Path not found: $searchPath"
    }
}
