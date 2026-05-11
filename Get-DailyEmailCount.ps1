# ============================
# Required setup
# - Automation Account created in Azure
# - FullAcces to $reportMailbox $sendAsMailbox variables (see end of script on adding permissions)
# - Microsoft.Graph.Mail
# ============================


# ============================
# Required modules (must be imported into Automation Account)
# - Microsoft.Graph.Authentication
# - Microsoft.Graph.Mail
# ============================
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Mail

# ============================
# Config
# ============================
$reportMailbox = "invoices@globalguardian.com"   # mailbox being counted
$sendAsMailbox = "invoices@globalguardian.com"   # From:
$toRecipients  = @(
    #"accounting@globalguardian.com",
    "lsimmons@globalguardian.com"
)

$logPrefix = "[Invoices Report]"

# ============================
# Connect to Graph (Managed Identity)
# ============================
Connect-MgGraph -Identity -NoWelcome
Write-Output "$logPrefix Connected to Microsoft Graph via Managed Identity"

# ============================
# Date calculations
# ============================
$todayStart = (Get-Date).Date
$yesterday  = $todayStart.AddDays(-1)
$monthStart = (Get-Date -Day 1).Date

function ToUtcIso ([datetime]$d) {
    [datetime]::SpecifyKind($d, 'Local').ToUniversalTime().ToString("o")
}

$yStartUtc = ToUtcIso $yesterday
$tStartUtc = ToUtcIso $todayStart
$mStartUtc = ToUtcIso $monthStart

# ============================
# Helper: get messages in time window
# ============================
function Get-Messages {
    param (
        [string]$Mailbox,
        [string]$StartUtc,
        [string]$EndUtc
    )

    $filter = "receivedDateTime ge $StartUtc and receivedDateTime lt $EndUtc"

    Get-MgUserMessage `
        -UserId $Mailbox `
        -Filter $filter `
        -All `
        -Property "internetMessageId"
}

# ============================
# Counts
# ============================
$yMsgs = Get-Messages -Mailbox $reportMailbox -StartUtc $yStartUtc -EndUtc $tStartUtc
$yesterdayTotal = (
    $yMsgs | Where-Object internetMessageId | Group-Object internetMessageId
).Count

$mMsgs = Get-Messages -Mailbox $reportMailbox -StartUtc $mStartUtc -EndUtc $tStartUtc
$mtdTotal = (
    $mMsgs | Where-Object internetMessageId | Group-Object internetMessageId
).Count

Write-Output "$logPrefix Yesterday=$yesterdayTotal MTD=$mtdTotal"

# ============================
# Build HTML
# ============================
$bodyHtml = @"
<html>
  <body style="font-family:Arial,Helvetica,sans-serif;">
    <h2>Invoices Email Report</h2>
    <p><strong>Mailbox:</strong> $reportMailbox</p>
    <p><strong>Yesterday ($(Get-Date $yesterday -Format 'MMMM dd, yyyy')):</strong>
       $yesterdayTotal unique emails</p>
    <p><strong>Month-to-Date (since $(Get-Date $monthStart -Format 'MMMM dd, yyyy') through yesterday):</strong>
       $mtdTotal unique emails</p>
    <p style="color:#777;font-size:12px;">
       Generated - $(Get-Date -Format 'yyyy-MM-dd HH:mm')
    </p>
  </body>
</html>
"@

# ============================
# Recipients
# ============================
$toObjects = $toRecipients | ForEach-Object {
    @{ EmailAddress = @{ Address = $_ } }
}

# ============================
# Send mail
# ============================
$message = @{
    Subject = "Invoices Daily Email Report - $(Get-Date -Format 'yyyy-MM-dd')"
    Body    = @{
        ContentType = "HTML"
        Content     = $bodyHtml
    }
    ToRecipients = $toObjects
}

Send-MgUserMail `
    -UserId $sendAsMailbox `
    -BodyParameter @{
        Message = $message
        SaveToSentItems = $true
    }

Write-Output "$logPrefix Report sent successfully"

Disconnect-MgGraph