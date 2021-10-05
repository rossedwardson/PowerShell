# Name    : Stats-VMDiskWeek_v7
# Purpose : This script will run through all the VM's on a given ESX host and export the stats to a CVS file.
# Version : 7.2
# Authors : LucD, VMware Powershell Forums & Tony Gent, SNS Limited.
# Edits: Ross Edwardson | 2.24.21



# Global Site Variables
# vCenter Login Variables
$sVCUser = "*" # holds the login name used to login to vcenter, local or domain
$SecurePassword = Get-Content '*\Savedcred.txt' | ConvertTo-SecureString
$UserCredential = New-Object System.Management.Automation.PSCredential -ArgumentList $sVCUser,$SecurePassword
$strVMWildCard = "*"                # use * for all machine, or use wildcard to limit, eg : "Sol*" for machines begining Sol
$strOutputLocation = "C*" # The default output location for for results, the file name is generated - just provide the path.
$sLogfile = "*"


# for Stats-VMDiskWeek

$strStatsOutput = "Stats-VMDisk"
$today5pm = (Get-Date -Hour 17 -Minute 0 -Second 0) # define the start time as 5pm YESTERDAY night.
# Define the number of days ago to start the scan.
#(Ideally -7 or lower. High numbers (-8 etc) returns 30 mins stats)
$intStartDay = -7 # stats for 1 days ago
# define the number of days ago to stop the scan.
#(Ideally -1 to return stats up to 5pm last night. -0 returns stats up to today )
$intEndDay = -0 # stats for 1 days ago (yesterday)
## -6, -1 returns 6 days worth of data from 5pm 6 days ago until 5pm last night.
## -7, -1 returns 7 days worth of data from 5pm 7 days ago until 5pm last night.
## -7, -0 returns 7 days worth of stats from 5pm 7 days ago until 2hrs ago.

# Create Log Files
write-host "Getting log file name"
Write-host "Log file is $sLogfile"

# Local Variables
# $arrMetrics = "virtualDisk.totalWriteLatency.average","virtualDisk.totalReadLatency.average",
#    "virtualDisk.numberReadAveraged.average","virtualDisk.numberWriteAveraged.average",
#    "virtualDisk.read.average","virtualDisk.write.average"
$arrMetrics = "virtualDisk.read.average","virtualDisk.write.average",
    "disk.read.average","disk.write.average","disk.maxTotalLatency.latest",
    "datastore.read.average","datastore.write.average"
    
## Begin Script

#Connect to VC
Connect-VIServer $sVCenter -Credential $UserCredential -ea SilentlyContinue
$arrVMs = Get-VM | where-object {$_.Name -like $strVMWildCard -and $_.PowerState -eq "PoweredOn" }
$iCountVMs = $arrVMs.Count
write-host "List of VM's Generated, $iCountVMs found."

# Create single output file to be appended to by all VMs
$strCSVSuffix = (get-date).toString('yyyyMMddHHmm')
$strCSVFile = $strOutputLocation + $strStatsOutput + "_" + $strCSVSuffix + ".csv"
write-host "Output file written to : $strCSVfile"

#Itterate through the Array for all VM's and ask for stats and export.
foreach($VM in $arrVMs)
{
write-host  "Getting VM Stats for VM : $VM"
$Report = Get-Stat -Entity $VM -Stat $arrMetrics -Start $today5pm.AddDays($intStartDay) -Finish $today5pm.AddDays($intEndDay) -ea SilentlyContinue

# Export the stats as a CSV file into the object : $csvExport
if ($Null -eq $Report)
{
write-host  "********  Stats for VM : $VM are shown as NULL  ********"
}
else
{
$oStatsObjects = @()
Foreach ($oEntry in $Report) {
$oObject = New-Object PSObject -Property @{
#Description = $oEntry.Description
Entity = $oEntry.Entity
#EntityId = $oEntry.EntityId
Instance = $oEntry.Instance
MetricId = $oEntry.MetricId
Timestamp = ($oentry.Timestamp).toString('dd/MM/yyyy HH:mm')
Value = $oEntry.Value
Unit = $oEntry.Unit
}
$oStatsObjects += $oObject
}
write-host  "Converting to CSV"
$csvExport = $oStatsObjects | ConvertTo-Csv -outvariable $csvOut -notypeinformation

#Appending the export object to the report CSV file.
write-host  "Exporting Data for VM : $VM"
$csvExport[0..($csvExport.count -1)] | foreach-object {add-content -value $_ -path $strCSVfile}
}

#Clear the value of $report to receive the next machines entries.
$Report=$null
$oStatsObjects=$null
}

# Disconnect from Virtual Center
write-host  "Script Complete : Disconnecting from vCenter."
Disconnect-VIServer -Confirm:$False
write-host  "vCenter Disconnect Completed. Script Closed.
