<#
Get all disabled users and their group memberships
1. Get disabled users
2. Get disabled users group memberships
Ross Edwardson @ CORA/CMI | 04.28.2021
#>

# Variables
$LogPath = "C:\Users\redwardson\OneDrive - CENTRAL OREGON RADIOLOGY AS\Documents\WindowsPowerShell\Scripts\Outputs\Logs\Disabled With Groups\Log.log"
$credentials = "C:\Users\redwardson\OneDrive - CENTRAL OREGON RADIOLOGY AS\Documents\WindowsPowerShell\Temp\SavedCreds_cora_redwardson_DJ-T570.xml"
$ExportPath = "C:\Users\redwardson\OneDrive - CENTRAL OREGON RADIOLOGY AS\Documents\WindowsPowerShell\Scripts\Outputs\CSVs\Disabled With Groups\DisbaledwithGroups.csv"

# Start script
Import-Module ActiveDirectory

# Start transcript
Start-Transcript $LogPath

# Get Disabled AD users
Get-ADUser -Credential $credentials -Filter * -Properties DisplayName,memberof,DistinguishedName,Enabled | ForEach-Object  {
    New-Object PSObject -Property @{
      UserName = $_.DisplayName
      DistinguishedName = $_.DistinguishedName
      Enabled = $_.Enabled
	Groups = ($_.memberof | Get-ADGroup | Select-Object -ExpandProperty Name) -join ";"
}
} | Select-Object UserName,@{l='OU';e={$_.DistinguishedName.split(',')[1].split('=')[1]}},Groups,Enabled | Export-Csv  $ExportPath –NTI

# Complete
Stop-Transcript