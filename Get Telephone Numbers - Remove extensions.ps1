<#
Get Telephone Numbers - Remove extensions like "x***"
1. Get All AD User's Phone Number Attributes
2. Backup Users
3. Create Hash of Active Users
4. Filter out Users with $Null
5. Filter for users with 'PAGE'
6. Filter for users with 'X***'
7. Set 'PAGE' users to $Null/clear
8. Remove 'x' from Users
9. Remove '.' from Users
10. Remove any spaces
11. Set Users Telephones
12. Verify Change
Ross Edwardson @ CMI/CORA | 11.10.2022
Rev 1 | Published
#>

# Variables
$DC = "*"
$LogPath = "*\Log.log"
$CredPath = "*.xml"
$Credentials = Import-CliXml -Path "$CredPath"
$SearchPath = "*"
$BackupPathBefore = "*\Removal_Before.csv"
$NPath = "*\NUsers.csv"
$PPath = "*\PUsers.csv"
$RPath = "*\RUsers.csv"
$BackupPathAfter = "*\Removal_After.csv"


# Script Start
# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

# Create Logfile
Start-Transcript -Path $LogPath
write-host "Starting transaction log and placing in location $LogPath"

## Get Active Users
try {
    $Users = @(Get-ADUser -Server $DC -Credential $Credentials -SearchBase "$SearchPath" -Properties SamAccountName, DistinguishedName, TelephoneNumber  {Enabled -eq $true})
    $Users | Select-Object -Property SamAccountName, DistinguishedName, TelephoneNumber | Export-CSV -Path $BackupPathBefore -NoTypeInformation -Force
}
catch {
    write-error "Get ADUsers Failed"
}
finally{
    $iCountUsers = $Users.Count
    write-host "List of Users Generated, $iCountUsers users changed."
}

# Create Hash
$FilterUsers = foreach ($User in $Users) {
    $FilterUsers = [ordered]@{
    'Name' = $User.SamAccountName;
    'DName' = $User.DistinguishedName;
    'Phone' = $User.TelephoneNumber
    }
    Write-Output (New-Object -TypeName PSObject -Property $FilterUsers)
}

# Filter out users Null Telephone
$NUsers = $FilterUsers | where {$_.Phone -ne $Null}
$NUsers | Export-CSV -Path $Npath -NoTypeInformation -Force

# Filter for page and export
$PUsers = $NUsers | Where {$_.Phone -like 'PAGE'}
$PUsers | Export-CSV -Path $PPath -NoTypeInformation -Force

# Filter x*** and export
$RUsers = $NUsers | where {$_.Phone -like "x***"}
$RUsers | Export-CSV -Path $RPath -NoTypeInformation -Force

# Clear PageFiltered values to ADUser. Can't Set value to $Null, can only clear.
try {
    foreach ($PFuser in $PageFiltered) {
        Set-Aduser -Identity $PFUser.Name -Server $DC -Credential $Credentials -Clear TelephoneNumber
    }
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -ForegroundColor red
}

# Modify RUsers Phone to match standard
$RFUsers = @{}
$RFUsers = try {
    foreach ($RUser in $RUsers) {
        $RFUsers = [ordered]@{
            'Name' = $RUser.Name
            'DName' = $RUser.DName
            'Phone' = $RUser.Phone -replace '[a-zA-Z]',''
        }
    write-Output (New-Object -TypeName PSObject -Property $RFUsers)
    }
}    
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -ForegroundColor red
}

# Remove any periods from RFUsers Phones
$FRFUsers = @{}
$FRFUsers = try {
    foreach ($RFUser in $RFUsers) {
        $FRFUsers = [ordered]@{
            'Name' = $RFUser.Name
            'DName' = $RFUser.DName
            'Phone' = $RFUser.Phone -replace '[.]',''
        }
        write-output (New-Object -TypeName PSObject -Property $FRFUsers)
    }
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -ForegroundColor red
}

# Remove Spaces from FRFUsers Phones
$FINALFRFUsers = @{}
$FINALFRFUsers = try {
    foreach ($FFRFUser in $FRFUsers) {
        $FINALFRFUsers = [ordered]@{
            'Name' = $FFRFUser.Name
            'DName' = $FFRFUser.DName
            'Phone' = $FFRFUser.Phone -replace '[ ]',''
        }       
        write-output (New-Object -TypeName PSObject -Property $FINALFRFUsers)
    }
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -ForegroundColor red
}

# Set FINALFRFUsers values to AD
try {
    foreach ($FINALUSER in $FINALFRFUsers) {
        set-aduser -Identity $FINALUser.Name -Server $DC -Credential $Credentials -replace @{TelephoneNumber=$($FinalUser.Phone)}
    }
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -ForegroundColor red
}

# Verify all active users Telephone Change
try {
    $UserVerification = @(Get-ADUser -Server $DC -Credential $Credentials -SearchBase "$SearchPath" -Properties SamAccountName, DistinguishedName, TelephoneNumber  {Enabled -eq $true})
    $UserVerification | Select-Object -Property SamAccountName, DistinguishedName, TelephoneNumber | Export-CSV -Path $BackupPathAfter -NoTypeInformation -Force
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -ForegroundColor red
}
finally{
    $iCountUsers = $Users.Count
    write-host "List of Users Generated, $iCountUsers users changed."
}

# Complete
Write-Host "Script complete."
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
Write-Host "I took $CreationTime to complete."
Stop-Transcript