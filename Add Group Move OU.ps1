<#
Move AD-User Object and Update Group
1. Get User DNs from CSV with User SAM
3. Add Users to Group
4. Move Users Object to New OU
Ross Edwardson @ CMI/CORA | 08.12.2021
#>

# Variables
$CSVPath = "*\Users.csv"
$LogPath = "*\Log.log"
$DC = "*"
$TargetPath = "*"
$Group = "*"
$Credentials = (Get-Credential)

# Start Script
# Start Transcript
Start-Transcript $LogPath

# Import Module
Import-Module ActiveDirectory

# Import CSV and save DistinguishedName to Variable
$UserDN = Import-CSV -Path $CSVPath | foreach-object {
    Get-ADUser -Identity $_.SamAccountName -Properties * | Select-Object DistinguishedName
}

# Add Users to Groups
foreach ($USAM in $UserDN) {
    Add-ADGroupMember -Identity $Group -Members $($USAM.DistinguishedName)
}

# Take Users DN and Move Object
foreach ($user in $UserDN) {
    Move-ADObject -Identity $($user.DistinguishedName) -TargetPath $TargetPath -Server $DC -Credential $Credentials
}

# Complete
Stop-Transcript