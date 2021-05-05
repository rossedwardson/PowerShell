<#
Update User Notes
1. Import CSV with user and notes info
2. Export old notes to CSV
3. Update users AD object
Ross Edwardson @ CMI/CORA | 05.03.2021
Rev 1.1 - *Added Backup* 05.05.2021
#>

# Variables
$CSVPath = "\CSV.csv"
$LogPath = "\Log.log"
$ExportPath = "\Backup.csv"

# Start Script
Import-Module ActiveDirectory

# Start Transcript
Start-Transcript $LogPath

# Import CSV and select username for backup
$CSV = Import-CSV -path $CSVPath -Delimiter ","

# Get old notes and export to CSV for backup
$Users = @()
foreach ($User in $CSV) { 
    $Users += get-aduser -Identity $($User.LoginID) -Properties Name, Info | Select-Object -Property Name, Info
}
$Users | Export-CSV $ExportPath -NoTypeInformation

# Update Notes Object
foreach ($row in $CSV) {
    set-aduser -Identity $($row.LoginID) -Replace @{info=$($row.Note)}
}

# Complete
Stop-Transcript