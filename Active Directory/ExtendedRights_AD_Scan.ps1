## This searches OU's/Domains for extended rights on objects. Useful for auditing potential indirect permissions on groups, comps, etc... ##

# Search common delegation targets
$filter = "(|(objectClass=domain)(objectClass=organizationalUnit)(objectClass=group)(sAMAccountType=805306368)(objectCategory=Computer))" 

# Search just OUs and Groups
#$filter = "(|(objectClass=organizationalUnit)(objectClass=group))"

# More filters can be found here: http://www.ldapexplorer.com/en/manual/109050000-famous-filters.htm

# Connect to DOMAINCONTROLLER using LDAP path, with USERNAME and PASSWORD
#$bSearch = New-Object System.DirectoryServices.DirectoryEntry("LDAP://DOMAINCONTROLLER/LDAP"), "USERNAME", "PASSWORD") 

# Connect to DOMAINCONTROLLER using LDAP path
$bSearch = New-Object System.DirectoryServices.DirectoryEntry("LDAP://DC1.contoso.com/DC=contoso,DC=com") 

$dSearch = New-Object System.DirectoryServices.DirectorySearcher($bSearch)
$dSearch.SearchRoot = $bSearch
$dSearch.PageSize = 1000
$dSearch.Filter = $filter #comment out to look at all object types
$dSearch.SearchScope = "Subtree"

# List of extended permissions available here: https://technet.microsoft.com/en-us/library/ff405676.aspx
$extPerms = '00299570-246d-11d0-a768-00aa006e0529', 'ab721a54-1e2f-11d0-9819-00aa0040529b', '0'
$results = @()

foreach ($objResult in $dSearch.FindAll())
{
    $obj = $objResult.GetDirectoryEntry()

    Write-Host "Searching... " $obj.distinguishedName

    $permissions = $obj.PsBase.ObjectSecurity.GetAccessRules($true,$false,[Security.Principal.NTAccount])
    
    $results += $permissions | Where-Object { $_.AccessControlType -eq 'Allow' -and ($_.ObjectType -in $extPerms) -and $_.IdentityReference -notin ('NT AUTHORITY\SELF', 'NT AUTHORITY\SYSTEM', 'S-1-5-32-548') } | Select-Object `
        @{n='Object'; e={$obj.distinguishedName}}, 
        @{n='Account'; e={$_.IdentityReference}},
        @{n='Permission'; e={$_.ActiveDirectoryRights}}
}
$results | Export-Csv C:\temp\ADPermissions.csv
