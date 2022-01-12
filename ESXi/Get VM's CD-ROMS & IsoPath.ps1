<#
Get All VMs with CD-ROMs and ISOs
1. Connect to vCenters
2. Load all VMs to array
3. Export VMs with CD-ROM and the ISO
Ross Edwardson @ CMI/CORA | 01.12.2022
Rev 1
#>

# Variables
$vCenters = "*", "*"
$LogPath = "*\Log.log"
$ExportPath = "*\CDROMs.csv"
$CredentialPath = "*.xml"
$RemoteCredential = Import-CliXml -Path "$CredentialPath"

# Start Script
# Start Transcript
Start-Transcript -path $LogPath

# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

#Modules
Import-Module VMware.PowerCLI

# Connect to vCenters
foreach ($vc in $vcenters) {     
    if( Connect-VIServer -server $vc -Protocol https -Credential $RemoteCredential -ErrorAction Ignore) {        
        Write-Host "Connected to $vc"  -ForegroundColor Cyan     
    }
    else {
         Write-Host "Failed to Connect to $vc"  -ForegroundColor Cyan
    }    
}

# Get VMs with CD-ROMs and ISO Path
$CDs = Get-VM | Where-Object {$_.PowerState –eq “PoweredOn”} | Get-CDDrive | Select-Object Parent, IsoPath
$CDs | Export-Csv $ExportPath -NoTypeInformation

# Finished
# Complete
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
Write-Host "I took $CreationTime to complete."
Disconnect-VIServer * -Confirm:$False
Stop-Transcript