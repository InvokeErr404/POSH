$shell = New-Object -ComObject "Shell.Application"
$shell.minimizeall()

$text = "This PC is past due for updates. Please reboot when convenient. Updates keep your PC operating efficiently and protect our systems from malicious threats. Please open a ticket if you have any questions by emailing helpdesk@contoso.com."

Add-Type -AssemblyName PresentationFramework

$msgBoxInput = [System.Windows.MessageBox]::Show($text,'Restart Computer','YesNo','Error')
switch ($msgBoxInput) {

'Yes' {
    Restart-Computer
 }

'No' {

 }

}
exit