<# DNS Zone Query and Trust Builder - Ver 1.2
1. Create/Check Backup Folder
2. Get/Check if DNS Zone Exists
3. Backup DNS Zone
4. Remove DNS Zone
5. Create Conditional Forwarders
6. Create Two-Way Forest Trust
7. Verify Forest Trust
Ross Edwardson @ CMI/CORA | 02/24/2021
#>

# Variables
$DNSServer = "*"
$DNSServer1 = "*"
$DNSServer2 = "*"
$ZoneName = "*"
$ZoneNameB = "*"
$FolderPath = "*"
$CredentialPath = "*\SavedCreds_*.xml"
$RemoteAdmin = "*" # Only input user name - no domain
$RemoteCredential = Import-CliXml -Path "$CredentialPath"
$RemoteContext = New-Object -TypeName "System.DirectoryServices.ActiveDirectory.DirectoryContext" -ArgumentList @( "Forest", $ZoneName, $RemoteAdmin, $RemoteCredential.GetNetworkCredential().Password)
$MasterServers = "*", "*"
$ReplicationScope = "Forest"
$LogPath = "*\Log.log"

# Script Start

# Create Logfile
Start-Transcript -Path $LogPath

write-host "Starting transaction log and placing in location $LogPath"

# Create and Check for Backup Folder
if (-not (Test-Path $FolderPath)) {
    Write-Host "Directory $FolderPath does not exist - creating directory"
    New-Item -Path $FolderPath -ItemType "Directory"
}
else {
    Write-host "Folder Exists"
    Write-Host "Moving On"
}

# Create Backup File
$FileSuffix = (get-date).toString('yyyyMMddHHmm')
$BackupPath = $FolderPath + $ZoneName + "-" + "Backup" + "_" + $FileSuffix + ".txt"
$BackupFile = $ZoneName + "-" + "Backup" + "_" + $FileSuffix + ".txt"
New-Item -ItemType "File" -Path $FolderPath -Name "$BackupFile"
write-host "Output file written to : $BackupPath"

# Check if DNS Zone Exists - If it does Create Backup
$DNSZoneCheck = @(Get-DNSServerZone -ComputerName $DNSServer)
if (($DNSZoneCheck).ZoneName -contains "$ZoneName") {
    #write-host "Zone $ZoneName exists"
    Export-DNSServerZone -Name "$ZoneName" -FileName "$BackupPath"
}
else {
    throw "Zone $ZoneName does not exist"
}

#  Remove DNS Zone
try {
Remove-DNSServerZone -ComputerName $DNSServer -Name $ZoneName -Verbose
}
catch {
    throw "Removing DNS Zone $ZoneName on $DNSServer Failed"
}
finally {
    write-host "DNS Zone: $ZoneName deleted from $DNSServer"
}

# Remove Zone from DNS Server 1
try {
    Remove-DNSServerZone -ComputerName $DNSServer1 -Name $ZoneName -Verbose
}
catch {
    throw "Removing DNS Zone $ZoneName on $DNSServer1 Failed"
}
finally {
    write-host "DNS Zone: $ZoneName deleted from $DNSServer1"
}

# Remove Zone from DNS Server 2
try {
    Remove-DNSServerZone -ComputerName $DNSServer2 -Name $ZoneName -Verbose
}
catch {
        throw "Removing DNS Zone $ZoneName on $DNSServer2 Failed"
}
finally {
    write-host "DNS Zone: $ZoneName deleted from $DNSServer2"
}

#  Create Conditional Forwarders Domain A
try{
    Add-DNSServerConditionalForwarderZone -ComputerName $DNSServer -Name $ZoneName -ReplicationScope $ReplicationScope -MasterServers $MasterServers
}
catch {
    Write-Error "Create Forwarder failed for: $ZoneName -> $ZoneNameB"
}

# Create Domain Trust
try {
    $RemoteForest = [System.DirectoryServices.ActiveDirectory.Forest]::getForest($RemoteContext)
    Write-Host "GetRemoteForest: Succeeded for domain $($RemoteForest)"
}
catch {
    Write-Error "GetRemoteForest: Failed:`n`tError: $($($_.Exception).Message)"
}
Write-Host "Connected to Remote forest: $($RemoteForest.Name)"
$Localforest=[System.DirectoryServices.ActiveDirectory.Forest]::getCurrentForest()
Write-Host "Connected to Local forest: $($Localforest.Name)"
try {
    $LocalForest.CreateTrustRelationship($RemoteForest,"Bidirectional")
    Write-Host "CreateTrustRelationship: Succeeded for domain $($RemoteForest)"
}
catch {
    Write-Error "CreateTrustRelationship: Failed for domain $($RemoteForest)`n`tError: $($($_.Exception).Message)"
}
finally {
    write-host "Trust Built!"
}

# Verify trust is built
$ADTrustCheck = @(Get-ADTrust -Filter *)
if (($ADTrustCheck).Target -contains "$ZoneName") {
    write-host "Trust for $ZoneName exists with $ZoneNameB"
}
else {
    throw "Trust for $ZoneName does not exist on $ZoneNameB"
}

# Verify Trust is BiDirectional
$ADTrustCheck = @(Get-ADTrust -Filter *)
if (($ADTrustCheck).Direction -contains "BiDirectonal") {
    write-host "Two-Way trust for $ZoneName exists with $ZoneNameB"
}
else {
    throw "Two-Way trust for $ZoneName does not exist on $ZoneNameB"
}

# Complete
Stop-Transcript
write-host "Script Complete"
