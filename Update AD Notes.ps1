<#
Update User Notes
1. Import CSV with user and notes info
2. Update users AD object
Ross Edwardson @ CMI/CORA | 05.03.2021
#>

# Variables
$CSVPath = ".csv"
$LogPath = "Log.log"

# Start Script
Import-Module ActiveDirectory

# Start Transcript
Start-Transcript $LogPath

# Import CSV
$CSV = Import-CSV -path $CSVPath -Delimiter ","

# Update Notes Object
foreach ($row in $CSV) {
    set-aduser -Identity $($row.LoginID) -Replace @{info=$($row.Note)}
}

# Complete
Stop-Transcript