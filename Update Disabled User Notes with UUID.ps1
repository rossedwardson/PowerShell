<#
Update Disabled User Notes with ME UUID
1. Import CSV with users disabled
2. Get UUID from csv
3. Get Users and export old notes
4. Create hash to update notes correctly
5. Update Notes
6. Export users and notes changed
Ross Edwardson @ CMI/CORA | 01.25.2023
#>

# Variables
$DC = "*"
$CSVPath = "*"
$LogDirectory = "*"
$LogName = "*"
$ExportPath = "*"
$CredentialPath = "*.xml"
$RemoteCredential = Import-CliXml -Path "$CredentialPath"

# Start Script
# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

# Import Module
Import-Module ActiveDirectory

# Checking log path exists, if not trying to create it.
$LogFilePathTest = Test-Path $LogDirectory
If ($LogFilePathTest -eq $False) {
    New-Item -Path $LogDirectory -ItemType "Directory"
}

# Getting time
$Now = Get-Date

# Creating log file name
$Log = $LogDirectory + $LogName + "_" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + ".log"

# Start Transcript
Start-Transcript -Path $Log -NoClobber

# Get CSV from Path
$CSVFile = Get-Childitem -Path $CSVPath | where {($_ -like "*.csv")}

# Create correct full path for import
$CSVFP = $CSVPath + $CSVFile

# Import CSV and select username for backup
$CSV = Import-CSV -Path $CSVFP

# Get UUID from ActionTime and remove newline break
$T = $CSV.ActionTime -replace "\n",''

# Select first result, only need 1
$T1 = $T[0]

# Cleanup UUID so we can use in export path
$T2 = $T1.Replace(" ","_")
$ST = $T2.Replace(":",".")

# Get old notes
$Users = @()
foreach ($User in $CSV) { 
    $Users += get-aduser -Server $DC -Credential $RemoteCredential -Identity $User.ObjectName -Properties SamAccountName, Info | Select-Object -Property SamAccountName, info
}

# Create CSV File Name
$BackupBeforeCSVName = "ME_DU-BC" + "_" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + "_" +"UUID_$ST" + ".csv"

# Create full backup path
$BackupBeforeCSV = $ExportPath + $BackupBeforeCSVName

# Export users before change
$Users | Export-CSV $BackupBeforeCSV -NoTypeInformation

# Create Hash
$FilteredUsers = foreach ($User in $Users) {
    $FilteredUsers = [ordered]@{
    'Name' = $User.SamAccountName;
    'Info' = $User.Info + " " + "|" + " " + "UUID:$T1"
    }
    Write-Output (New-Object -TypeName PSObject -Property $FilteredUsers)
}

# Update Notes Object
foreach ($row in $FilteredUsers) {
    set-aduser -Server $DC -Credential $RemoteCredential -Identity $($row.Name) -Replace @{info=$($Row.Info)}
}

# Get new notes and export to CSV for Reference
$ChangedUsers = @()
foreach ($U2 in $($FilteredUsers).Name){
    $ChangedUsers += get-aduser -Server $DC -Credential $RemoteCredential -Identity $U2 -Properties SamAccountName, Info | Select-Object -Property SamAccountName, info
}

# Create CSV File Name
$BackupAfterCSVName = "ME_DU-AC" + "_" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + "_" +"UUID_$ST" + ".csv"

# Create full backup path
$BackupAfterCSV = $ExportPath + $BackupAfterCSVName

# Export users after change
$ChangedUsers | Export-CSV $BackupAfterCSV -NoTypeInformation

# Complete
Write-Host "Script complete."
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
Write-Host "I took $CreationTime to complete."
Stop-Transcript