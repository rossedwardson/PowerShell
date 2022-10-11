<#
Remove Mobile Telephone Numbers from O365
1. Connect to AzureAD
2. Get all active users
3. Filer for Mobile numbers like 'PAGE
4. Filter for Mobile Numbers in "x***" format
5. Connect to MSOL
6. Set MSOLUser -Mobile "$Null"
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

# Connect to MSOL
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

# Filter for Page + Mobile numbers like "x***"
$NUser = $Muser | where {$_.Mobile -ne $Null}
$PUser = $Nuser | Where {$_.Mobile -like 'PAGE'}
$Ruser = $Nuser | where {$_.Mobile -like "x***"}
$FMuser = $Ruser + $Puser

# Backup Users before Change
$FMUser | Export-CSV -Path $BackupPath

# Set FMUsers Mobile to $Null
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