# Define the OU to search (Distinguished Name)
$ou = "OU=Computers,DC=contoso,DC=local"

# Get all computers in the OU and nested OUs
$computers = Get-ADComputer -Filter * -SearchBase $ou -SearchScope Subtree -Properties Name, LastLogonTimestamp

# Convert and display results
$computers | Select-Object Name, 
@{
    Name = "LastLogonDate";
    Expression = {
        if ($_.LastLogonTimestamp) {
            [DateTime]::FromFileTime($_.LastLogonTimestamp)
        } else {
            "Never"
        }
    }
} | Export-csv "C:\temp\ActiveMachines.csv"