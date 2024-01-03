<#
Update Disabled User Notes with ME UUID
1. Import XLSX
2. Extract usable data
3. Get Users and export old notes and groups
4. Create hash to export memberOf correctly
5. Create hash to update notes correctly
6. Update Notes
7. Export users and notes changed
8. Rename and Move Completed AuditReport
Ross Edwardson @ CMI/CORA | 01.25.2023
Rev 1.1 - Added backup up for groups
Rev 1.2 - Updated xlsx I&E, and report cleanup to streamline the workflow | 01.02.2024
#>

# Variables
$DC = "*"
$CSVPath = "*"
$LogDirectory = "*"
$LogName = "ME_DU"
$ExportPath = "*"
$CompleteCSVPath = "*"
$CredentialPath = "*"
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
$CSVFile = Get-Childitem -Path $CSVPath | where {($_ -like "*.xlsx")}

# Import CSV and select username for backup
$CSV = Import-Excel -Path $CSVFile -NoHeader

# Remove $null spaces
$CleanCSV = $CSV | Where-Object {$_.P8 -ne $null}

# Select the columns we want
$RevisedCSV = $CleanCSV | Select P8, P9

# Remove un-needed first line
$ReRevisedCSV = $RevisedCSV | Select -skip 1

# Rename columns to something useable
$FilterCols = $ReRevisedCSV | Select -Property @{label="ActionTime";expression={$($_.P8)}},@{label="ObjectName";expression={$($_.P9)}}

# Get UUID from ActionTime and remove newline break
$T = $FilterCols.ActionTime # -replace "\n",''

# Select first result, only need 1
$T1 = $T[0]

# Cleanup UUID so we can use in export path
$T2 = $T1.Replace(" ","_")
$ST = $T2.Replace(":",".")

# Get old notes
$Users = @()
foreach ($User in $FilterCols) { 
    $Users += get-aduser -Server $DC -Credential $RemoteCredential -Identity $User.ObjectName -Properties SamAccountName, Info, MemberOf | Select-Object -Property SamAccountName, info, @{Name="MemberOf";Expression={$_.MemberOf -Join ";"}}
}

# Create CSV File Name
$BackupBeforeCSVName = "ME_DU-BC" + "_" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + "_" +"UUID_$ST" + ".csv"

# Create full backup path
$BackupBeforeCSV = $ExportPath + $BackupBeforeCSVName

# Create Hash with Group info
$GroupUserHash = foreach ($User in $Users) {
    $GroupUserHash = [ordered]@{
        'Name' = $User.SamAccountName
        'Info' = $User.Info
        'Group' = $User.MemberOf
    }
    Write-Output (New-Object -TypeName PSObject -Property $GroupUserHash)
}

# Convert Hash to CSV and export
$CSVUsers = $GroupUserHash
[PSCustomObject]$CSVUsers | ConvertTo-CSV -NoTypeInformation
$CSVUsers | Export-CSV -Path $BackupBeforeCSV -NoTypeInformation -Force -ErrorAction SilentlyContinue

# Create Hash for updated Notes
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

#Rename AuditReport
$CompletedFileName = "AuditReportCompleted" + "@" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + "_" +"UUID_$ST" + ".xlsx"
Rename-Item $CSVFile -NewName $CompletedFileName

# Move AuditReport
Get-Childitem -Path $CSVPath | where {($_ -like "*.xlsx")} | Move-Item -Destination $CompleteCSVPath

# Complete
Write-Host "Script complete."
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
Write-Host "I took $CreationTime to complete."
Stop-Transcript