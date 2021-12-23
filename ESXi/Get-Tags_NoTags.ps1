<#
Get VM Tags
1. Connect to vCenter
2. Load all VMs to array
3. Export Tags to CSV
4. Export VMs without Tags to CSV
Ross Edwardson @ CMI/CORA | 08.05.2021
Rev 1.3 | 12.23.2021
#>

# Variables
$vCenters = "*", "*"
$LogPath = "*.log"
$ExportPath = "*.csv"
$ExportPath2 = "*.csv"
$CredentialPath = "*.xml"
$RemoteCredential = Import-CliXml -Path "$CredentialPath"

# Start Script
# Start Transcript
Start-Transcript -path $LogPath

# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

# Connect to vCenters
foreach ($vc in $vcenters) 
{     
    if( Connect-VIServer -server $vc -Protocol https -Credential $RemoteCredential -ErrorAction Ignore)
    {        
        Write-Host "Connected to $vc"  -ForegroundColor Cyan     
 }
    else
  {
         Write-Host "Failed to Connect to $vc"  -ForegroundColor Cyan
    }    
}

# Get VMs
$VMs = Get-VM | Select-Object Name

# Get VM Tags
$Tags = foreach ($VM in $VMs) {
    Get-TagAssignment -Entity $($VM.Name)
}
$Tags | Select-Object Entity, Tag | Export-CSV -Path $ExportPath -NoTypeInformation

# Get VMs without Tags
$VMsNoTags = Get-VM | Where-Object {(Get-TagAssignment $_) -eq $null}
$VMsNoTags | Select-Object Name | Export-CSV -Path $ExportPath2 -NoTypeInformation

# Complete
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
Write-Host "I took $CreationTime to complete."
Disconnect-VIServer * -Confirm:$False
Stop-Transcript