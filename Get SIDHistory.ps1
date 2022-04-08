<#
Get SID and  SID History
1. Get AD Users that are enabled based off OU Search Path
2. Filter Output for Name, SAM, SID, and SID History
3. Export
Ross Edwardson @ CMI/CORA | 04.08.2022
Rev 1
#>

# Variables
$DC = "*"
$SearchPath = "*"
$Credentials = (Get-Credential)
$LogDirectory = "*"
$LogName = "*"
$CSVPath = "*"
$HeaderName = "*"

#Script Start
# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

# Checking log path exists, if not trying to create it.
$LogFilePathTest = Test-Path $LogDirectory
If ($LogFilePathTest -eq $False) {
    New-Item -Path $LogDirectory -ItemType "Directory"
}

# Getting time
$Now = Get-Date

# Creating log file name
$Log = $LogDirectory + $LogName + "_" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + ".log"

# Start Transcript
Start-Transcript -Path $Log -NoClobber

# Find Enabled Users
$EnabledUsers = @(Get-ADUser -Server $DC -Credential $Credentials -SearchBase "$SearchPath" -Properties * -filter {Enabled -eq $true})

# Filter for wanted properties
$EnabledFilter = $EnabledUsers | Select Name, SamAccountName, SID, @{name="$HeaderName";expression={$_.SIDHistory -join ","}}

# Export CSV
$EnabledFilter | Export-CSV -Path $CSVPath -Force -NoTypeInformation

# Complete
Write-Host "Script complete."
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
Write-Host "I took $CreationTime to complete."
Stop-Transcript