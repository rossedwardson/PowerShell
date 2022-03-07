<#
Set NIC RegistrationEnabled RegKey:
1. Checks for administrator context, and re-launches if false.
2. Get RegKey GUID.
3. Filter for GUID that has DNS name from CMIPACS.
4. Backup Filtered GUID.
5. Set RegistrationEnabled Key to 1.
6. Backup Hive after Change.
Ross Edwardson @ CMI/CORA | 03.02.2022
Rev 1 | Release
#>

# Self-Elevating to run as admin
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  # Relaunch as an elevated process:
  Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
  exit
}

# Variables
# All Variables will need to be called to local directories after test
$HiveLocation = "HKLM:\SYSTEM\ControlSet001\Services\Tcpip\Parameters\Interfaces\"
$NameServer1 = "*"
$NameServer2 = "*"
$NameServer3 = "*"
$KeyToSet = "RegistrationEnabled"
$KeyValue = "1"
$KeyType = "DWORD"
$LogDirectory = "*"
$BackupPath = "*\Outputs\"

# Script Start
# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

# Checking log path exists, if not trying to create it.
$LogFilePathTest = Test-Path $LogDirectory
If ($LogFilePathTest -eq $False) {
    New-Item -Path $LogDirectory -ItemType "Directory"
}

# Getting time
$Now = Get-Date

# Creating log file name
$Log = $LogDirectory + "\" + "Set_NIC_Registration" + "_" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + ".log"

# Start Transcript
Start-Transcript -Path $Log -NoClobber

# Checking if backup path exists, if not trying to create it.
$BackupFilePathTest = Test-Path $BackupPath
if ($BackupFilePathTest -eq $False) {
    New-Item -Path $BackupPath -ItemType "Directory"
}

# Query Hive for Keys and join them to hashtable
$FirstQuery = Get-ChildItem -Path $HiveLocation
$HivePath = @{}
$HivePath = $FirstQuery.Name
$HivePath -join ", "

# Create usable paths for later.
Foreach ($path in $HivePath) {
    $HivePathAppeded = $HivePath.replace('HKEY_LOCAL_MACHINE','HKLM:')
}

# Get GUID to Modify
$TrueGUID = @(Foreach ($Path in $HivePathAppeded) {
    $Filter2 = Get-ItemProperty -Path "$Path"
    $Filter2 | Foreach-Object {
        if (($Filter2).NameServer -match "$NameServer1" -or ($Filter2).NameServer -match "$NameServer2" -or ($Filter2).NameServer -match "$NameServer3") {
            $TrueGUIDPath = $Path
            Write-Host "$TrueGUIDPath contained Name Servers: $NameServer1, $NameServer2, or $NameServer3."
            Write-Host "Exporting "$Filter2.PSChildName" in XML for safe keeping."
            $BackupFile = "$BackupPath" + $Filter2.PSChildName + ".xml"
            $Filter2 | Export-CliXml -Path "$BackupFile"
        }
        Else {
            Write-Host "$Path did not contain Name Servers: $NameServer1, $NameServer2, or $NameServer3. Skipping."
        }
        
    }
}) 

# Test if registry exists before changing.
$FirstCheck = Get-ItemProperty -Path "$TrueGUIDPath"
if (($FirstCheck).RegistrationEnabled -match "$KeyValue") {
    Write-Host "RegKey and Value already exist. Exporting regkey to backup with a new backup name, then exiting."
    $OutputName = "RegKey_Output" + "_" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + ".csv"
    $FirstCheckBackup = "$BackupPath" + "$OutputName"
    $FirstCheck | Export-CSV -Path "$FirstCheckBackup" -NoTypeInformation -Force
    exit
}
else {
    Write-Host "Key and Value missing or not set correctly, continuing."
}

# Set Registry Key
try {
    Set-ItemProperty -Path "$TrueGUIDPath" -Name "$KeyToSet" -Type "$KeyType" -Value "$KeyValue"
}
Catch {
    Write-Host "Error Happened in the Set Key phase."
}

# Verify key has been changed
$ChangedHive = Get-ItemProperty -Path "$TrueGUIDPath"
if (($ChangedHive).RegistrationEnabled -eq "$KeyValue") {
    Write-Host "Changed successfully. Backing up RegHive."
    $ChangedHive = Get-ItemProperty -Path "$TrueGUIDPath"
    $ACBFile = $BackupPath + $ChangedHive.PSChildName + "_" + "AfterChange" + ".xml"
    $ChangedHive | Export-CliXml -Path "$ACBFile"
}
else {
    Write-Host "Error happened in setting key phase or key doesn't exist."
}

# Complete
Write-Host "Script complete."
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
Write-Host "I took $CreationTime to complete."
Stop-Transcript