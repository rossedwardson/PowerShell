<#
Update Mobile Numbers from User's AD TelephoneNumber Attribute.
1. Get All AD User's Phone Number Attributes and Export to CSV
2. Import CSV from Step 1.
3. Copy telephonenumber to mobile attribute.
4. Verify Change by exporting users for verification.
Ross Edwardson @ CMI/CORA | 7.19.2021
#>

# Variables
$DC = "*"
$SearchPath = "*"
$LogPath = "*\Log.log"
$BackupPath = "*\PhoneNumbers_Before.csv"
$BackupPath1 = "*\PhoneNumbers_After.csv"
$CredPath = "C*.xml"
$Credentials = Import-CliXml -Path "$CredPath"


# Script Start
# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

# Create Logfile
Start-Transcript -Path $LogPath
write-host "Starting transaction log and placing in location $LogPath"

# Get AD Users and Phone Numbers || Acceptable Properties TelephoneNumber, Mobile, Fax, HomePhone, Pager, IPPhone
try {
    $Users = @(Get-ADUser -Server $DC -Credential $Credentials -SearchBase "$SearchPath" -Properties * -filter {Enabled -eq $true})
    $Users | Select-Object -Property SamAccountName, DistinguishedName, TelephoneNumber, Mobile | Export-CSV -Path $BackupPath -NoTypeInformation -Force
}
catch {
    write-error "Get ADUsers Failed"
}
finally{
    $iCountUsers = $Users.Count
    write-host "List of Users Generated, $iCountUsers users found."
}

# Import CSV from Above
$Puser = Import-CSV -Path $BackupPath

# Replace Mobile Number with TelephoneNumber then Export for verification
foreach ($Puser1 in $Puser) {
    Set-ADObject -Identity $Puser1.DistinguishedName ` -replace @{Mobile=$($Puser1.TelephoneNumber)}
}

# Verify Mobile Number Change
try {
    $UsersAfter = @(Get-ADUser -Server $DC -Credential $Credentials -SearchBase "$SearchPath" -Properties * -filter {Enabled -eq $true})
    $UsersAfter | Select-Object -Property SamAccountName, DistinguishedName, TelephoneNumber, Mobile | Export-CSV -Path $BackupPath1 -NoTypeInformation -Force
}
catch {
    write-host "Error Happened in Verification"
}
finally {
    $iCountUsers = $UsersAfter.Count
    write-host "List of Users Generated, $iCountUsers users found."
}

# Complete
Write-Host "Script complete"
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
Write-host "I took $CreationTime to compelete"
Stop-Transcript