## Bulk Update User enrolled devices to "Corporate Owned". Don't do if you have BYOD devices in your org ##

Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.ReadWrite.All'

$graphversion = "beta"

$url = "https://graph.microsoft.com"

$endpoint = "deviceManagement/managedDevices?`$filter="

$filter = "ownerType eq 'personal' and managementAgent eq 'mdm' and (operatingSystem eq 'iOS')"

$uri = "$url/$graphversion/$endpoint$filter"

$devices = Invoke-MgGraphRequest -Method Get -OutputType PSObject -Uri $uri

$body = '

{

ownerType:"company"

}'

foreach($device in $devices.value) {

$uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($device.id)"

Invoke-MgGraphRequest -Uri $uri -Body $body -method Patch -ContentType "application/json"

}