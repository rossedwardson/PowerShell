<#
Increase CPU cores on running VM | Rev 1.1
1. Shutdown VM
2. Increase Core Count
3. Startup VM
Ross Edwardson | 04.13.2021
#>

# Variables
$LogLocation = "*\Log.log"
$vCenter = "*"
$VMs = "*" 
$CPUCoreCount = "*"
$CorePerSocket = "*"
# $MemoryGBCount = "*"

# Start Script

# Start Transcript
Start-Transcript -path $LogLocation

# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

# Connect VIServer
Connect-VIServer $vCenter -Credential (Get-Credential)

# Shtudown, wait for complete VM power off, increase CPU, turn VM on.
foreach ($VM in $VMs) {
    Shutdown-VMGuest $VM -Confirm:$false
    Sleep 120
    Set-VM $VM -NumCPU $CPUCoreCount -CoresPerSocket $CorePerSocket -Confirm:$False
    Start-VM $VM
}

# Complete
disconnect-viserver $vCenter -confirm:$false
Write-Host "Script complete"
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
$CreationTime
Stop-Transcript
