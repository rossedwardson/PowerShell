<#
Remove Guest Users from O365
1. Connect to AzureAD
2. Query guest users
3. Backup objects to be removed
4. Remove AzureAD objects
Ross Edwardson @ CMI/CORA | 3.6.24
Rev 1.1 | 3.8.24 | Update dynamic logs and csv names
#>

# Variables
$LogDirectory = "${env:ScriptDir}\Logs\O365-GuestDisable\"
$LogName = "O365-GuestDisable"
$ExportPath = "${env:ScriptDir}\Outputs\CSVs\O365-GuestDisable\"
$ExportName = "O365-GuestDisable"

##Script Start##
# Start timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

# Checking log path exists, if not trying to create it.
$LogFilePathTest = Test-Path $LogDirectory
If ($LogFilePathTest -eq $False) {
    New-Item -Path $LogDirectory -ItemType "Directory"
}

# Getting time
$Now = Get-Date

# Set log file name
$Log = $LogDirectory + $LogName + "_" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + ".log"

# Start transcript
Start-Transcript -Path $Log -NoClobber

# Import AzureAD module
Import-Module AzureAD

# Connect to AzureAD
Connect-AzureAD

# Get Azure guest users
$Users = Get-AzureADUser -filter "userType eq 'Guest'"

# Checking export path exists, if not trying to create it.
$ExportPathTest = Test-Path $ExportPath
If ($ExportPathTest -eq $False) {
    New-Item -Path $ExportPath -ItemType "Directory"
}

# Initialize CSV name
$CSV = $ExportPath + $ExportName + "_" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + ".csv"

# Backup users to be removed
$Users | Export-Csv -Path $CSV -NoTypeInformation

# Initialize error log
$ErrorLog = $LogDirectory + "Error_" + $LogName + "_" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + ".log"

# Soft delete AzureAD objects
foreach ($Object in $($Users).ObjectID) {
    try {
        Remove-AzureADUser -ObjectID $Object -ErrorAction Continue
    }
    catch {
        # Write the error to the console
        Write-Host $_.Exception.Message

        # Write the error to the error log
        Add-Content -Path $ErrorLog -Value $_.Exception.Message
    }
}

# Complete
Write-Host "Script complete"
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
$CreationTime
Stop-Transcript