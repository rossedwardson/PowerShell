<#
Assign MSOL Licenses
1. Import list of users from CSV
2. Get users UPN from Full Name and save to variable
3. Connect to MSOL Resources (This requires manual signin if MFA is involved.)
4. Get users current licenses
5. Sort by EXO Plan 1 and EXO Plan 2
6. Update MSOL License for each group
Ross Edwardson @ CMI/CORA | 12.27.2021
Rev 1 || Release
#>

# Variables
$LogPath = "*.log"
$CSVImport = "*.csv"
$CSVExport = "*.csv"
$CSVExport2 = "*.csv"
$StandardPack = "reseller-account:STANDARDPACK" # E1
$EnterprisePack = "reseller-account:ENTERPRISEPACK" # E3
$EXO1Options = New-MsolLicenseOptions -AccountSkuId "reseller-account:STANDARDPACK" -DisabledPlans "INTUNE_O365"   # Microsoft is dumb, you can only call the plans (apps) you want to disable, per License type (E1, E3, etc). Anything not 'disabled' will become active.
$EXO2Options = New-MsolLicenseOptions -AccountSkuId "reseller-account:ENTERPRISEPACK" -DisabledPlans "INTUNE_O365"    # Microsoft is dumb, you can only call the plans (apps) you want to disable, per License type (E1, E3, etc). Anything not 'disabled' will become active.

# Script Start
# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

# Create Logfile
Start-Transcript -Path $LogPath -Append
write-host "Starting transaction log and placing in location $LogPath"

# Import Modules
Import-Module MSOnline
# Import-Module AzureAD

# Connect to O365 Services
Connect-MsolService
# Connect-AzureAD

# Import CSV and Save to Variable
$licensedUsers = Import-CSV $CSVImport -Header @("User") | foreach {Get-MsolUser -UserPrincipalName $_.user}

# Get Current License and Apps
Foreach ($user in $licensedUsers) {
    $licenses = $user.Licenses
    $licenseArray = $licenses | foreach-Object {$_.AccountSkuId}
    $licenseString = $licenseArray -join ", "
    $AppArray = (Get-MsolUser -UserPrincipalName ($User).UserPrincipalName).Licenses.ServiceStatus
    $Apps = $AppArray.ServicePlan.ServiceName -join ", "
    Write-Host "$($user.displayname) has $licenseString" -ForegroundColor Blue
    $LicensedObjects = [pscustomobject][ordered]@{
        DisplayName       = $user.DisplayName
        Licenses          = $licenseString
        UserPrincipalName = $user.UserPrincipalName
        AppNames          = $Apps
    }
    # Backup Current Licenses
    $LicensedObjects | Export-CSV -Path $CSVExport -NoTypeInformation -Append -Force
}

# Import CSV from above cause I'm dumb and don't know how to get the above variable to save all info... herp derp
$AllUsers = Import-CSV $CSVExport

# Sort EXO Plan 1 Users
$EXO1Conditions = {$_.Licenses -match "reseller-account:STANDARDPACK"}
$EXO1Users = $AllUsers | Where-Object $EXO1Conditions

# Sort EXO Plan 2 Users
$EXO2Conditions = {$_.Licenses -match "reseller-account:ENTERPRISEPACK"}
$EXO2Users = $AllUsers | Where-Object $EXO2Conditions

# Enable EXO 1 License
foreach ($EXO1User in $EXO1Users) {
    Set-MsolUserLicense -UserPrincipalName ($EXO1User).UserPrincipalName -AddLicenses $StandardPack -LicenseOptions $EXO1Options
}

# Enable EXO 2 License
foreach ($EXO2User in $EXO2Users) {
    Set-MsolUserLicense -UserPrincipalName ($EXO2User).UserPrincipalName -AddLicenses $EnterprisePack -LicenseOptions $EXO2Options
}

# Export changed licenses for verification
# Get Current License and Apps
Foreach ($user2 in $licensedUsers) {
    $licenses2 = $user2.Licenses
    $licenseArray2 = $licenses2 | foreach-Object {$_.AccountSkuId}
    $licenseString2 = $licenseArray2 -join ", "
    $AppArray2 = (Get-MsolUser -UserPrincipalName ($User).UserPrincipalName).Licenses.ServiceStatus
    $Apps2 = $AppArray2.ServicePlan.ServiceName -join ", "
    Write-Host "$($user.displayname) has $licenseString" -ForegroundColor Blue
    $LicensedObjects2 = [pscustomobject][ordered]@{
        DisplayName       = ($user2).DisplayName
        Licenses          = $licenseString2
        UserPrincipalName = ($user2).UserPrincipalName
        AppNames          = $Apps2
    }
    # Backup Current Licenses
    $LicensedObjects2 | Export-CSV -Path $CSVExport2 -NoTypeInformation -Append -Force
}

# Script Complete
Write-Host "Script complete"
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
$CreationTime
#Disconnect from MSOL
[Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState()
Stop-Transcript 