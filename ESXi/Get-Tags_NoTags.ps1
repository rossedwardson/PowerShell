<#
Get VM Tags
1. Connect to vCenter
2. Load all VMs to array
3. Export Tags to CSV
4. Export VMs without Tags to CSV
Ross Edwardson @ CMI/CORA | 08.05.2021
#>

# Variables
$vCenter = "*"
$LogPath = "*\Log.log"
$ExportPath = "*\Tags.csv"
$ExportPath2 = "*\NoTags.csv"
$CredentialPath = "*.xml"
$RemoteCredential = Import-CliXml -Path "$CredentialPath"

# Start Script
# Start Transcript
Start-Transcript -path $LogPath

# Connect to vCenter
connect-viserver "$vCenter" -Credential ($RemoteCredential)

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
Disconnect-VIServer -Confirm:$False
Stop-Transcript