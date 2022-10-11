<#
Remove Mobile Telephone Numbers from O365
1. Connect to AzureAD
2. Get all active users
3. Filter for Mobile Numbers in "x***" format
4. Connect to MSOL
5. Set MSOLUser -Mobile "$Null"
Ross Edwardson @ CMI/CORA | 10.11.2022
#>

# Variables
$LogPath = "*"
$BackupPath = "*"

# Script STart
# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

# Create Logfile
Start-Transcript -Path $LogPath
write-host "Starting transaction log and placing in location $LogPath"

# Connect to Azure AD
Connect-AzureAD

# Connect to MSOL as we can't use AzureAD due to ADSync
Connect-MsolService

# Get Active Users in AzureAD
try {
    $Users = @(Get-AzureADUser -All $True | where-object {$_.AccountEnabled -like "True"})
    $Users | Select-Object UserPrincipalName
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -ForegroundColor red
}
finally {
    $iCountUsers = $Users.Count
    Write-Host "List of users generated. $iCountUsers found."
}

# Get Users UPN & Mobile
try {
    $Muser = foreach ($User in $Users) {
        Get-AzureADUser -ObjectId $User.UserPrincipalName | Select-Object UserPrincipalName, Mobile
    }
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -ForegroundColor red
}

# Filter for user WITH Mobiles like "x***"
$FMUser = $Muser | where {$_.Mobile -ne $Null -AND $_.Mobile -ne 'PAGE' -AND $_.Mobile -notlike "x***"}

# Backup Users before Change
$FMUser | Export-CSV -Path $BackupPath

# Set FMUsers Mobile to "$Null"
try {
    foreach ($User in $FMUser) {
        set-msoluser -UserPrincipalName $User.UserPrincipalName -Mobile "$null"
    }
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -ForegroundColor red
}

# Complete
Write-Host "Script complete."
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
Write-Host "I took $CreationTime to complete."
Stop-Transcript