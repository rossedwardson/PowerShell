<#
Update DPI on All Monitors and set to 100%
1. Checks for all types of ScaleFactor monitors
2. Checks to see if regkey exists - if yes, update.
3. If above is false, then create keys.
# Log out and back in after running.
Ross Edwardson @ CMI/CORA | 05.11.2021
Rev 1.1
#>

# Variables
$dpiValue = "-1" # -1 = 100%/Off
$AppliedDPIValue = "00000096" # 00000096 = 100%
$AppliedDPIValue2 = "00000096" # 00000096 = 100%
$activeMonitorsRegPath = "HKCU:\Control Panel\Desktop\PerMonitorSettings"
$activeMonitorsRegPath2 = "HKCU:\Control Panel\Desktop\WindowMetrics"
$genericMonitorsList = Get-ChildItem HKLM:\System\CurrentControlSet\Control\GraphicsDrivers\ScaleFactors

# Start Script
Start-Transcript

# Get Monitor types installed
Write-Host( [string]::Format("Found {0} ScaleFactors monitors",$genericMonitorsList.Length));

# Test Keys, Update/Create keys.
foreach ($genericMonitor in $genericMonitorsList){
	$tempRegPath = $activeMonitorsRegPath + '\' + $genericMonitor.PsChildname;
	if (Test-Path -Path $tempRegPath) {
        Write-Host('Updating values for monitor - ' + $genericMonitor.PsChildname)
		Set-ItemProperty -Path $tempRegPath -Name 'DpiValue' -Value $dpiValue -Type 'DWord' –Force
        Set-ItemProperty -Path $tempRegPath -Name 'AppliedDPI' -Value $AppliedDPIValue -Type 'Dword' -Force
		Set-ItemProperty -Path $activeMonitorsRegPath2 -Name 'AppliedDPI' -Value $AppliedDPIValue2 -Type 'DWord' -Force
	} 
	else {
        Write-Host('Creating new key and values for monitor - ' + $genericMonitor.PsChildname)
		New-Item -Path $activeMonitorsRegPath -Name $genericMonitor.PsChildname –Force | Out-Null
		New-ItemProperty -Path $tempRegPath -Name 'DpiValue' -PropertyType 'DWord' -Value $dpiValue –Force  | Out-Null
        New-ItemProperty -Path $tempRegPath -Name 'AppliedDPI' -PropertyType 'DWord'  -Value $AppliedDPIValue -Force | Out-Null
		New-ItemProperty -Path $activeMonitorsRegPath2 -Name 'AppliedDPI' -PropertyTpe 'DWord' -Value $AppliedDPIValue2 -Force | Out-Null
	}
}

# Complete
Stop-Transcript