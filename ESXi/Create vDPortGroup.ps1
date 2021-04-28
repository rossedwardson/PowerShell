<#
Create dvSwtich and add dvPortGroup | Rev 1.1
1. Connect to vCenter
2. Create dvPortGroups
Ross Edwardson @ CORA/CMI | 04.07.2021
#>

# Variables
$vCenter = "*"
$LogPath = "*"
$vLANPrefix = "*"
$vLANID= @(*)
$vDSwitch = "*"
$ActiveUplink = "*"
$StandbyUplink = "*"


# Start Script
# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

# Start Transcript
Start-Transcript -path $LogPath

# Connect to vCenter
connect-viserver "$vCenter" -Credential (Get-Credential)

# Get and Set vDPortGroups
$vlanid | foreach {
Get-VDSwitch -Name "$vDSwitch" | New-VDPortgroup -Name $vLANPrefix$_ -VlanId $_ -RunAsync:$true
Get-VDSwitch -Name "$vDSwitch" | Get-VDPortgroup -Name $vLANPrefix$_ | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort "$ActiveUplink" -StandbyUplinkPort "$StandbyUplink"
}

# Complete
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
$CreationTime
Stop-Transcript
