<#
Set extensionAttributes
1. Get Computers in OU 
2. Backup before changing
3. Set extensionAttribute for location
4. Verify change
5. Export Changed Values
6. Start AlertMedia Sync
Ross Edwardson @ CMI/CORA | 03.16.2022
Rev 1 | Release
#>

# Variables
$LogDirectory = "*"
$BackupPath = "*"
$OUs = @()
$OUs += [PSCustomObject]@{
    SearchBase = '*'
} # Enter in OU to Query
$OUs += [PSCustomObject]@{
    SearchBase = '*'
}
$OUs += [PSCustomObject]@{
    SearchBase = '*'
}
$OUs += [PSCustomObject]@{
    SearchBase = '*'
}
$FilterNames = @("*") # @("Value1", "Value2")

#Script Start
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
$Log = $LogDirectory + "Filename" + "_" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + ".log"

# Start Transcript
Start-Transcript -Path $Log -NoClobber

# Checking if backup path exists, if not trying to create it.
$BackupFilePathTest = Test-Path $BackupPath
if ($BackupFilePathTest -eq $False) {
    New-Item -Path $BackupPath -ItemType "Directory"
}

# Get computers in OU
$Computers = @()
$Computers = @(foreach ($OU in $OUs.SearchBase) {
    $Filter = get-adcomputer -SearchBase $OU -Filter * -Properties Name, DistinguishedName, extensionAttribute1 | Select Name, DistinguishedName, extensionAttribute1
    $Filter = @($Filter | where {$_.Name -notmatch ('(' + [string]::Join(')|(', $FilterNames) + ')')})
    $FilterComputers += $Filter
})

# Backup computers before change
$BackupFile = $BackupPath + "AttributeUpdate" + "_" + "BeforeChange" + "_" + "ValueName" + "_" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + ".csv"
$FilterComputers | Export-CSV -Path $BackupFile -NoTypeInformation -Force

# Set extensionAttribute
foreach ($Computer in $FilterComputers) {
    # set-adcomputer -Identity ($Computer).Name -clear "extensionAttribute1" # Used in testing.
    set-adcomputer -Identity ($Computer).Name -Add @{extensionAttribute1="Value1"} # Employee Workstation
}

# Verify Set
$ChangedCheck = @{}
$ChangedCheck = @(foreach ($Computer in $FilterComputers) {
    get-adcomputer -Identity ($Computer).Name -Properties Name, DistinguishedName, extensionAttribute1 | Select Name, DistinguishedName, extensionAttribute1
})

# Export to CSV
$ExportFile = $BackupPath + "AttributeUpdate" + "_" + "AfterChange" + "_" + "ValueName" + "_" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + ".csv"
$ChangedCheck | Export-CSV -Path $ExportFile -NoTypeInformation -Force

# Start AlertMedia CMD Sync
Start-Process -FilePath "*ADSyncConsole.exe" -ArgumentList '-c "*.config" -s -v'

# Complete
Write-Host "Script complete."
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
Write-Host "I took $CreationTime to complete."
Stop-Transcript