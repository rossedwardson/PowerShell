<#
Add Group to O365 Teams
1. Get users in Group
2. Connect to Microsoft Teams
3. Add users to MSTeams
Ross Edwardson @ CORA/CMI | 03.10.2023
Rev 1
#>

#Variables
$LogDirectory = "*"
$Group = "*"
$TeamsID = "*"

# Script STart
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
$Log = $LogDirectory + $LogName + "_" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + ".log"

# Start Transcript
Start-Transcript -Path $Log -NoClobber

#Import Microsoft Teams
Import-Module -Name MicrosoftTeams

# Connect to O365 Teams
connect-microsoftteams

# Get members in Technologist
$AllMembers = Get-AdGroupMember -Identity $Group

# Get sams and emails of users
$SAM = @()
$SAM = ForEach ($User in ($AllMembers).SamAccountName) {
    get-aduser -Identity $User -Properties SamAccountName, EmailAddress | Select-Object -Property SamAccountName, EmailAddress
}

# Add users to group
foreach ($User in ($SAM).emailAddress) {
    try {
        add-teamuser -GroupId $TeamsID -User $User
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -ForegroundColor red
    }
}

# Complete
Write-Host "Script complete."
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
Write-Host "I took $CreationTime to complete."
Stop-Transcript