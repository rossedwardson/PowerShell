<#
Set all active users password change to false
1. Get active users
2. Set active users change password to false
Ross Edwardson @ CMI/CORA | 10.31.22
Rev 1.1
#>

# Variables
$DC = "*"
$SearchPath = "*"
$LogDirectory = "*"
$RemoteCredential = (Get-Credential)

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
$Log = $LogDirectory + "ActiveUsers" + "_" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + ".log"

# Start Transcript
Start-Transcript -Path $Log -NoClobber

# Get Enabled Users
$EnabledUsers = @(Get-ADUser -Server $DC -Credential $RemoteCredential -SearchBase "$SearchPath" -Properties UserPrincipalName -filter {Enabled -eq $true})

# Set EnabledUsers change password false
Foreach ($User in ($EnabledUsers).SamAccountName) {
    try {
        set-aduser $User -ChangePasswordAtLogon $false
    }
    catch{
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -ForegroundColor red
    }
}

# Complete
Write-Host "Script complete"
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
$CreationTime
Stop-Transcript