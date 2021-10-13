<#
Add regkey and value
1. Check for Hive & Create if missing
2. Set key value
Ross Edwardson @ CMI/CORA | 10.13.2021
Rev 1
#>

# Variables
$RegPath = "*"
$LogDirectory = "*"

# Script Start
# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

# Checking log path exists, if not trying to create it
$LogFilePathTest = Test-Path $LogDirectory

# Creating if false
IF ($LogFilePathTest -eq $False) {
    New-Item -Path $LogDirectory -ItemType "Directory"
}

# Getting time
$Now = Get-Date

# Creating log file name
$Log = $LogDirectory + "\$RegKey_" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + ".log"

# Verify path exists if not create
Start-Transcript -Path $Log -NoClobber
if (-Not(Test-Path “$RegPath”)) {
    New-Item -Path $RegPath -Force
}
# Set regkey value
Set-ItemProperty -Path $RegPath -Name "RpcAuthnLevelPrivacyEnabled" -Type Dword -Value 00000000

# Complete
Write-Host "Script complete"
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
Write-Host "I took $CreationTime to complete."
Stop-Transcript