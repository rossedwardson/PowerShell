<#
Purpose: Get disabled users in AD and convert those users to shared mailboxes.
1. Get disabled users in Disabled Users OU.
2. Load EMS 2010 into session.
3. Convert disabled users to shared mailboxes.
Ross Edwardson @ CMI/CORA | 3.26.2021
Rev 1.2
#>

# Variables
$DC = "*"
$BackupPath = "*"
$SearchPath = "*"
$LogPath = "*\Log.log"


# Script Start

# Create Logfile
Start-Transcript -Path $LogPath
write-host "Starting transaction log and placing in location $LogPath"

# Get Disabled Users
Import-Module ActiveDirectory
try {
$DisabledUsers = @(Get-ADUser -Server $DC -Credential $UserCredential -SearchBase "$SearchPath" -filter {Enabled -eq $false})
$DisabledUsers | Select-Object -Property UserPrincipalName | export-csv -Path $BackupPath -NoTypeInformation -Force
}
catch {
    write-error "Get ADUsers Failed"
}
finally{
    $iCountUsers = $DisabledUsers.Count
    write-host "List of Users Generated, $iCountUsers users found."
}

# Load EMS for 2010
Add-PSsnapin Microsoft.Exchange.Management.PowerShell.E2010

# Convert Disabled Users to Shared mailboxes.
foreach($User in ($DisabledUsers).UserPrincipalName)
{
try{
    set-mailbox -Identity $User -type Shared
}
catch {
    write-host "Error setting $User to Shared"
}
}
Write-Host "Script Complete"
Stop-Transcript
