<#
Get all disabled users and their group memberships
1. Get disabled users
2. Get disabled users group memberships
Ross Edwardson @ CORA/CMI | 04.28.2021
#>

# Variables
$DC = ""
$LogPath = "Log.log"
$CredentialPath = ""
$UserCredential = Import-CliXml -Path $CredentialPath
$ExportPath = "DisbaledwithGroups.csv"

# Start script
Import-Module ActiveDirectory

# Start transcript
Start-Transcript $LogPath

# Get Disabled AD users
Get-ADUser -Server $DC -Credential $UserCredential -Filter {Enabled -eq $false} -Properties DisplayName,memberof,DistinguishedName | ForEach-Object  {
    New-Object PSObject -Property @{
        UserName = $_.DisplayName
        DistinguishedName = $_.DistinguishedName
	    Groups = ($_.memberof | Get-ADGroup | Select-Object -ExpandProperty Name) -join ";"
    }
} | Select-Object UserName,@{l='OU';e={$_.DistinguishedName.split(',')[1].split('=')[1]}},Groups,Enabled | Export-Csv  $ExportPath  -NoTypeInformation

# Complete
Stop-Transcript