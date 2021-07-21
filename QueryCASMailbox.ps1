<#
Query CAS ActiveSync Status
1. Get Enabled Users from AD
2. Load EMS.2010 into session
3. Query CASMailbox for ActiveSync
Ross Edwardson @ CORA/CMI | 07.15.2021
#>

# Variables
$DC = "*"
$SearchPath = "*"       # OU Path to limit Search.
$BackupPath = "*\CASMailboxes.csv"
$CSVPath = "*\CASMailboxes.csv"
$LogPath = "*\Log.log"
$CredPath = "*.xml"
$Credentials = Import-CliXml -Path "$CredPath"
$ExchangeFQDN = '*'     # Leave the literal quotes.

# Script Start
# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

# Create Logfilee
Start-Transcript -Path $LogPath
write-host "Starting transaction log and placing in location $LogPath"

# Get Enabled Users
Import-Module ActiveDirectory
try {
$EnabledUsers = @(Get-ADUser -Server $DC -Credential $Credentials -SearchBase "$SearchPath" -filter {Enabled -eq $true})
$EnabledUsers | Select-Object -Property UserPrincipalName | export-csv -Path $BackupPath -NoTypeInformation -Force
}
catch {
    write-error "Get ADUsers Failed"
}
finally{
    $iCountUsers = $EnabledUsers.Count
    write-host "List of Users Generated, $iCountUsers users found."
}

# Load EMS
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchangeFQDN/PowerShell/ -Authentication Kerberos -Credential $Credentials
Import-PSSession $Session -DisableNameChecking

# Get ActiveSync Settings
foreach ($User in ($EnabledUsers).UserPrincipalName)
{
try{
    get-casmailbox -Identity $User | Export-CSV -Path $CSVPath -NoTypeInformation -Append
}
catch {
    write-host "Error getting $User CAS ActiveSync Setting"
}
}

# Complete
Write-Host "Script complete"
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
$CreationTime
Write-host "I took $CreationTime to compelete"
Remove-PSSession $Session
Stop-Transcript