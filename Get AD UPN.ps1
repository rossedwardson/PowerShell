<#
Get AD Users UPN from Full Name
1. Import CSV
2. Get UPN
3. Export to CSV
Ross Edwardson @ CORA/CMI | 12.21.2021
Rev 1.3
#>

# Variables
$CSVImport = "*\Techs.csv"
$CSVPath = "*\ADUPN.csv"
$LogPath = "*\Log.log"

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

# Get UPN
foreach ($User in $Users) {
    $FullName = @()
    $FullName = $User.First + " " + $User.Last
    get-aduser -filter "Name -like $('$FullName')" -Properties UserPrincipalName | Select-Object -Property UserPrincipalName | Export-CSV -Path $CSVPath -NoTypeInformation -Append -Force
}

# Complete
Write-Host "Script complete"
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
$CreationTime
Stop-Transcript 