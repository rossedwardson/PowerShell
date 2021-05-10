<#
Get All AD Users HomeFolder Path
1. Create backup file
2. Get AD Users and Save old Home Directory Path to CSV
3. Update Home Dir to new server
As the AD GUI creates the folder and sets permissions, we must do this ourselves
4. Set Permissions to only named user.
Ross Edwardson @ CMI/CORA | 05.10.2021
Rev 1.2
#>

# Variables
$LogPath = "*\Log.log"
$SearchBase = "*"
$ExportPath = "*\ADHomeFolders\"
$ExportFileType = ".csv"
$FileSuffix = (get-date).toString('yyyyMMddHHmm')
$BackupFile = "Backup" + "_" + $FileSuffix + "$ExportFileType"
$CredPath = "*"
$Credentials = Import-CliXml -Path "$CredPath"
$HomeDirectoryPath = "*"
$HomeDriveLetter = "U"
$FolderPath = "*"
$PathType = "Directory"
$PSDriveName = "UserFolder"
$FileSystemAccessRights = [System.Security.AccessControl.FileSystemRights]”FullControl”
$InheritanceFlags = [System.Security.AccessControl.InheritanceFlags]”ContainerInherit, ObjectInherit”
$PropagationFlags = [System.Security.AccessControl.PropagationFlags]”None”
$AccessControl = [System.Security.AccessControl.AccessControlType]”Allow”

# Start Script
# Start Transcript
Start-Transcript $LogPath -Append
Write-Host "Log started at: $LogPath" -ForegroundColor 'Cyan'

# Import Modules
Import-Module ActiveDirectory

# Start Timer
Write-Host "Timer Started"
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

# Create Backup File
New-Item -ItemType "File" -Path $ExportPath -Name "$BackupFile"

# Concat Path and File
$FullBackupPath = -join("$ExportPath", "$BackupFile")
write-host "CSV will be export to : $FullBackupPath" -ForegroundColor 'White' -BackgroundColor 'DarkCyan'

# Verify no PSDrives exist for upcoming operations.
$PSDrive = @(Get-PSDrive)
if (($PSDrive).Name -contains "$PSDriveName") {
    write-host "PSDrive $PSDriveName does exist. Moving on."  
}
else {
    write-host "PSDrive $PSDriveName does not exist! Creating." -ForegroundColor 'White' -BackgroundColor 'DarkBlue'
    New-PSDrive -Name "$PSDriveName" -PSProvider Filesystem -Root $FolderPath -Credential $Credentials
}

# Get all users in specifc OU. Export some property to csv.
$Users = @()
$Users = get-aduser -Filter * -SearchBase $SearchBase -Properties * | Select-Object -Property DistinguishedName, SamAccountName, HomeDirectory
$iCountUsers = $Users.Count
write-host "List of Users Exported. I found $iCountUsers users."
$Users | Export-CSV $FullBackupPath -NoTypeInformation

# Change all HomeDirs to new server, create folder if it doesn't exist.
foreach ($User in $Users) {
    try {
        $FullHomeDir = -join("$HomeDirectoryPath", "$($User.SamAccountName)")
        New-Item -Path $($FullHomeDir) -ItemType $PathType -Force
            write-host "Creating Folder @ $($FullHomeDir)"
            $IdentityReference = $($User.SamAccountName)
            $ACL = Get-ACL $FullHomeDir
            $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule ($IdentityReference,$FileSystemAccessRights,$InheritanceFlags,$PropagationFlags,$AccessControl)
            $ACL.SetAccessRule($AccessRule)
            $ACL | Set-ACL $FullHomeDir
            set-aduser -Identity $($User.SamAccountName) -HomeDirectory $FullHomeDir -HomeDrive $HomeDriveLetter
    }
    catch {
        write-host "Error Happened somewhere in this try statement."
    }
}

# Test Path after Creation
foreach ($Path in $FullHomeDir) {
    if (!(Test-Path $Path)) {
        Write-Host "$User path does not exist. Check for errors."
    }
    else {
        Write-Host "All Good."
    }
}

# Complete
Write-Host "Script complete" -ForegroundColor 'Cyan'
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
write-host "Script took $CreationTime to run." -ForegroundColor 'Cyan'
Stop-Transcript 