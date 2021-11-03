<#
Get Thick VMDKs
1. Connect to vCenter
2. Get VMs with drives not like Thin type
3. Export VMs to CSV
Ross Edwardson @ CMI/CORA | 11.03.2021
Rev 1
#>

# Variables
$vCenter = "coravcenter6.cmillc.org"
$LogPath = "C:\Users\redwardson\OneDrive - CENTRAL OREGON RADIOLOGY AS\Documents\WindowsPowerShell\Scripts\VMware\Thick vs Thin\Log.log"
$ExportPath = "C:\Users\redwardson\OneDrive - CENTRAL OREGON RADIOLOGY AS\Documents\WindowsPowerShell\Scripts\VMware\Thick vs Thin\VMs.csv"
$CredentialPath = "C:\Users\redwardson\OneDrive - CENTRAL OREGON RADIOLOGY AS\Documents\WindowsPowerShell\Temp\SavedCreds_cora_redwardson_DJ-T570.xml"
$RemoteCredential = Import-CliXml -Path "$CredentialPath"

# Script Start
# Start Transcript
Start-Transcript -path $LogPath

# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
$stopwatch.Start()

# Connect to vCenter
connect-viserver "$vCenter" -Credential ($RemoteCredential)

# Get Thick VMDKs
$DriveType = Get-Datastore | Get-VM | Get-HardDisk | Where {$_.storageformat -ne "Thin" } | Select Parent, Name, CapacityGB, storageformat
$DriveType | Export-CSV $ExportPath

# Complete
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
Write-Host "I took $CreationTime to complete."
Disconnect-VIServer -Confirm:$False
Stop-Transcript