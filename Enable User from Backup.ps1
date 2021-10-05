<# 
Enable Users en Mass Ver 1.2
Ross Edwardson @ CMI/CORA | 2.25.2021
#>

# Variables

$Report = "*"
$DC = "*"
$RemoteAdminB = "*"
$RemoteAdminPasswordB = Get-Content '*\Savedcred.txt' | ConvertTo-SecureString
$UserCredential = New-Object System.Management.Automation.PSCredential -ArgumentList $RemoteAdminB,$RemoteAdminPasswordB
$LogPath = "*"

# Script Start

# Create Logfile

Start-Transcript -Path $LogPath

write-host "Starting transaction log and placing in location $LogPath"

# Import Users that were disabled
Import-CSV -Path $Report | ForEach-Object { 
    $User = $_.sAMAccountName
    enable-ADAccount $User -Server $DC -Credential $UserCredential
}

#Complete

write-host "Users Enabed from backup"
Stop-Transcript
