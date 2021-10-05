<#
Disk Space Cleanup
1. Clean Windows temp locations
2. Clean Teams Cache locations
Ross Edwardson @ CMI/CORA | 10.05.2021
Rev 0.1 | Building
#>

# Self-Elevating to run as admin
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  # Relaunch as an elevated process:
  Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
  exit
}
& $ScriptLocation

# Variables
$LogDirectory = "*\Logs"
$TeamsLocation = "C:\Users\*\AppData\Roaming\Microsoft\Teams\*"
$TeamsCacheFolders = 'application cache', 'blob storage', 'databases', 'GPUcache', 'IndexedDB', 'Local Storage', 'tmp'
$WindowsTempLocation = "C:\Windows\*"
$WindowsTempFolders = ('Temp', 'Prefetch')
$UserTempLocations  = "C:\Users\*\AppData\Local\Temp\*"
$ScriptLocation = '*\DiskClean.ps1'

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
$Log = $LogDirectory + "\PowerOff" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + ".log"

# Starting logging
Start-Transcript -Path $Log -NoClobber

# Clear Windows Temp Folders
Get-ChildItem $WindowsTempLocation -Directory | Where-Object name -in ($WindowsTempFolders) | ForEach-Object {Remove-Item $_.FullName -Recurse -Force -Whatif}

# Clear User Temp Folders
Get-ChildItem $UserTempLocations -Directory | ForEach-Object {Remove-Item $_.FullName -Recurse -Force -WhatIf}

# Clear Teams Folders
Get-ChildItem $TeamsLocation -directory | Where-Object name -in ($TeamsCacheFolders) | ForEach-Object {Remove-Item $_.FullName -Recurse -Force -WhatIf}

# Complete
Write-Host "Script complete"
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
$CreationTime
Stop-Transcript