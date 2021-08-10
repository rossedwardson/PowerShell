<#
Get VMs
1. Connect to vCenter
2. Load all VMs to array
3. Export VMs to CSV
Ross Edwardson @ CMI/CORA | 08.10.2021
#>

# Variables
$vCenter = "*"
$LogPath = "*\Log.log"
$ExportPath = "*\VMs.csv"
$CredentialPath = "*.xml"
$RemoteCredential = Import-CliXml -Path "$CredentialPath"

# Start Script
# Start Transcript
Start-Transcript -path $LogPath

# Connect to vCenter
connect-viserver "$vCenter" -Credential ($RemoteCredential)

# Get VMs
$VMs = Get-VM | Select-Object Name
$VMs | Export-CSV -Path $ExportPath -NoTypeInformation

# Complete
Disconnect-VIServer -Confirm:$False
Stop-Transcript