# Import the Active Directory module
Import-Module ActiveDirectory

# Define the DN of the OU to exclude
$excludedOU = "OU=ServiceAccounts,DC=contoso,DC=com"

# Define the properties to retrieve for each user
$properties = @(
    'GivenName',
    'Surname',
    'Name',
    'UserPrincipalName',
    'Title',
    'Department',
    'Manager',
    'Enabled',
    'pwdLastSet',
    'StreetAddress',
    'TelephoneNumber'
)

# Get all users in the domain
$allUsers = Get-ADUser -Filter * -SearchBase "OU=Branches,DC=contoso,DC=com" -Properties $properties

# Filter out users that are in the excluded OU
$usersNotInExcludedOU = $allUsers | Where-Object { $_.DistinguishedName -notlike "*$excludedOU*" }

# Initialize an array to hold the results
$result = @()

# Loop through each user and create a custom object with the required properties
foreach ($user in $usersNotInExcludedOU) {
    # Resolve the manager's name if it exists
    $managerName = if ($user.Manager) {
        (Get-ADUser -Identity $user.Manager -Property DisplayName).DisplayName
    } else {
        ''
    }

    # Convert pwdLastSet to a readable date format if it exists
    $formattedPwdLastSet = if ($user.pwdLastSet -ne $null -and $user.pwdLastSet -ne 0) { 
        ([datetime]::FromFileTime($user.pwdLastSet)).ToString("MM/dd/yyyy hh:mm:ss tt zzz") 
    } else { 
        'Never' 
    }

    # Create a custom object for each user with the desired properties
    $result += [PSCustomObject]@{
        FirstName       = $user.GivenName
        LastName        = $user.Surname
        DisplayName     = $user.Name
        Email           = $user.UserPrincipalName
        JobTitle        = $user.Title
        Department      = $user.Department
        Manager         = $managerName
        Enabled         = $user.Enabled
        PasswordLastSet = $formattedPwdLastSet
        StreetAddress   = $user.StreetAddress
        TelephoneNumber = $user.TelephoneNumber
    }
}

# Export the results to a CSV file
$result | Export-Csv -Path "C:\temp\ADUserDetails.csv" -NoTypeInformation

# Output the path of the exported file for confirmation
Write-Output "Exported user details to C:\temp\ADUserDetails.csv"
