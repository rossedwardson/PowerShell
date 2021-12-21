<#
Query Users Mobile Device Exchange
1. Import CSV with users
2. Load EMS.2016 into session
3. Query Exchange for Mobile Device
Ross Edwardson @ CORA/CMI | 12.09.2021
Rev 1.1
#>

# Variables
$CSVImport = "C:\Users\redwardson\OneDrive - CENTRAL OREGON RADIOLOGY AS\Documents\WindowsPowerShell\Scripts\Reports\ExchMobile\Techs.csv"
$CSVPath = "C:\Users\redwardson\OneDrive - CENTRAL OREGON RADIOLOGY AS\Documents\WindowsPowerShell\Scripts\Outputs\CSVs\ExchMobile\ExchMobile.csv"
$LogPath = "C:\Users\redwardson\OneDrive - CENTRAL OREGON RADIOLOGY AS\Documents\WindowsPowerShell\Scripts\Outputs\Logs\ExchMobile\Log.log"
$CredPath = "C:\Users\redwardson\OneDrive - CENTRAL OREGON RADIOLOGY AS\Documents\WindowsPowerShell\Temp\SavedCreds_cora_redwardson_DJ-T570.xml"
$Credentials = Import-CliXml -Path "$CredPath"
$ExchangeURL = 'exchange-2016.cmillc.org'

# Start Script
# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

# Create Logfilee
Start-Transcript -Path $LogPath -Append
write-host "Starting transaction log and placing in location $LogPath"

# Import Users from CSV
$Users = Import-CSV $CSVImport -Header @("First","Last")

# Import AD
Import-Module ActiveDirectory

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchangeURL/PowerShell/ -Authentication Kerberos -Credential $Credentials
Import-PSSession $Session -DisableNameChecking

# Get SAM and Mobile Device
foreach ($User in $Users) {
    $FullName = @()
    $FullName = $User.First + " " + $User.Last
    $ADUser = get-aduser -filter "Name -like $('$FullName')" -Properties DistinguishedName, SamAccountName | Select-Object -Property DistinguishedName, SamAccountName
    Get-ActiveSyncDeviceStatistics -Mailbox $($ADUser.SamAccountName) | Export-CSV -Path $CSVPath -NoTypeInformation -Append -Force
}

# Complete
Write-Host "Script complete"
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
$CreationTime
Remove-PSSession $Session
Stop-Transcript 