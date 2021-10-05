<#
Update Manager Attribute for AD Users - Rev 1.3
1. Get Manager's Name
2. Import users by CSV
3. Update Managers Name
Ross Edwardson @ CMI/CORA | 04.05.2021
#>

# Variables
$CSVPath = "*.csv" # Path to CSV in comma separated format with header FirstName,LastName
$LogPath = "*\Log.log" # Path for Transcript
$ManagerName = "*" # Manager's Full Name

##
# Start Script
Import-Module ActiveDirectory

#Start Transcript
Start-Transcript $LogPath

# Get Managers SAM
$ManagerSAM = Get-ADUser -Filter "Name -like '$ManagerName'" | select -expand SamAccountName

# Import Users from CSV and get sAMAccountName
$Users = Import-CSV $CSVPath -Delimiter "," | 
ForEach-Object {
    get-aduser -Filter "GivenName -like '$($_.FirstName)' -and Surname -like '$($_.LastName)'" | Select-Object -ExpandProperty samAccountName
}

# Change Manager for Each User
foreach ($User in $Users) {
    set-aduser -Identity "$User" -Manager "$ManagerSAM" -PassThru
}

# Verify Users changed
foreach ($User in $Users) {
    get-aduser -Identity "$User" -Properties Manager
}

# Complete 
Stop-Transcript
