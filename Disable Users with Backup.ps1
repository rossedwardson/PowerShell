<# 
Disable Users en Mass Ver 1.1
Ross Edwardson @ CMI/CORA | 2.25.2021
#>

# Variables

$FolderPath = "*"
$DC = "*"
$SearchBase = "*"
$RemoteAdminB = "*"
$RemoteAdminPasswordB = Get-Content '*\Savedcred.txt' | ConvertTo-SecureString
$UserCredential = New-Object System.Management.Automation.PSCredential -ArgumentList $RemoteAdminB,$RemoteAdminPasswordB
$LogPath = "*"

# Script Start

# Start Log File

Start-Transcript -Path $LogPath

write-host "Starting transaction log and placing in location $LogPath"

#Check and create folder

if (-not (Test-Path $FolderPath)) {
    Write-Host "Directory $FolderPath does not exist - creating directory"
    New-Item -Path $FolderPath -ItemType "Directory"
}
else {
    Write-Host "Folder Exists"
    Write-Host "Moving On"
}

# Create Backup File

$FileSuffix = $DC + "-" + "AD"
$BackupPath = $FolderPath + "Backup" + "_" + $FileSuffix + ".csv"
$BackupFile = "Backup" + "_" + $FileSuffix + ".csv"
New-Item -ItemType "File" -Path $FolderPath -Name "$BackupFile"
write-host "Output file written to : $BackupPath"


#Export Users

try {
    $Report = @(Get-ADUser -server $DC -credential $UserCredential -searchbase $SearchBase -Filter 'enabled -eq $True')
    $Report | Select-Object -Property sAMAccountName | export-csv -Path $BackupPath -notypeinformation -Force
}
catch {
    write-error "Get ADUsers Failed"
}
finally {
    $iCountUsers = $Report.Count

write-host "List of Users Generated, $iCountUsers users found."
}


# Disable Users

foreach($User in $Report)
{
try {
    disable-adaccount -Identity $User
}
catch {
    write-host "Error disabling: $User"
}
}

# Complete
Stop-Transcript
