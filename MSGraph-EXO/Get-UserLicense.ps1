## Gets a list of users based on license type by SKU. SKU's can be found here: https://learn.microsoft.com/en-us/entra/identity/users/licensing-service-plan-reference ##

# Connect MgGraph
Connect-MgGraph -Scopes "User.Read.All","Organization.Read.All"

# Get license
$LicenseSku = (Get-MgSubscribedSku -All | Where-Object SkuPartNumber -eq "{LICENSESKU}").SkuId

# Get users with license and export to csv
Get-MgUser -All -ConsistencyLevel eventual -Filter "assignedLicenses/any(x:x/skuId eq $LicenseSku)" -Select "displayName,userPrincipalName,accountEnabled" |
  Export-Csv C:\Temp\F3Users.csv -NoTypeInformation
