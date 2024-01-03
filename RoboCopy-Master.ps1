<#
Robocopy Master Script
1. Give permissions to folders and files
2. File Compare between source and destination
3. Start robocopy jobs
4. Clear Net Use source for saftey
5. Combine all logs into one master log
6. Move solo log files to complete dir for additonal runs
Ross Edwardson @ CMI/CORA | 05.10.2023
Rev 1.4 - Added File Compare for Purge - 06.30.2023
#>
# Folder Variables for limited RoboCopy. Folder structure: isarchivedrive -> year -> month -> day.
$Day = *
$Month = *
$Year = *
$isarchivedrive = "*"
$LogDir = "*"
$LogName = "*"
$max_jobs = 8
# Drive Mounts
net use "*:" "*"
net use "*" "*"
# Variables 2 - No edits required
$tstart = get-date
$src = "*:\$isarchivedrive\$year\$Month\$day\"
$dest = "*:\isarchive\$year\$month\$day\"
$log = "*:\$LogDir\$isarchivedrive\$month\$day\"
$logdest = "$log" + "Complete\"
$masterpath = "C:\Scripts\$LogDir\$isarchivedrive\$month\$day\$LogName-$month-$day.log"
$icaclslog = "$masterpath" + "_" + "icacls.log"
$diffpath = "$masterpath" + "_" + "Compare.csv"

# Script Start
# Start Script
# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

# Create Logfile
Start-Transcript -Path $icaclslog -Append
write-host "Starting transaction log and placing in location $icaclslog"

# Take Permissions
icacls "$src\*" /grant "*:(OI)(CI)F" /T

# File Compare
$orginal = Get-ChildItem -Path $src -Recurse
$Pure = Get-ChildItem -Path $dst -Recurse
$Diff = Compare-Object -ReferenceObject $orginal -DifferenceOjbect "$Pure"
$Diff | Export-CSV -Path $diffpath -NoTypeInformation

# icacls file compare complete timer
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
$CreationTime
Stop-Transcript

# Start Robos
$files = ls $src
$files | %{
$ScriptBlock = {
param($name, $src, $dest, $log)
$log += "\$name-$(get-date -f yyyy-MM-dd-mm-ss).log"
robocopy $src$name $dest$name > $log /NP /FP /MT:12 /NDL /V /E /COPY:DATSO /NOOFFLOAD /R:1 /W:1 /FFT /MIR
Write-Host $src$name " completed"
 }
$j = Get-Job -State "Running"
while ($j.count -ge $max_jobs) 
{
 Start-Sleep -Milliseconds 500
 $j = Get-Job -State "Running"
}
 Get-job -State "Completed" | Receive-job
 Remove-job -State "Completed"
Start-Job $ScriptBlock -ArgumentList $_,$src,$dest,$log
 }
#
# No more jobs to process. Wait for all of them to complete
#

While (Get-Job -State "Running") { Start-Sleep 2 }
Remove-Job -State "Completed" 
  Get-Job | Write-host

$tend = get-date

new-timespan -start $tstart -end $tend

# Clear Net Use for safety
net use *: /delete

# Combine Log Files into one
Get-ChildItem $log -include *.log -rec | ForEach-Object {gc $_; ""} | Out-file $masterpath

# Clear log folder
Move-Item -path $Log\*.log -Destination $Logdest