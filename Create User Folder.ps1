<#
User Folder Creation Rev 1.5
1. Get User from Read Host.
2. Check User Folder
3. Create User Folder
4. Assign Full Permissions to Users Folder to only User
Ross Edwardson @ CORA/CMI | 04.02.2021
#>

# Variables
$FolderPath = "*"
$LogLocation = "*\Log.log"
$AccessControl = "Allow"
$InheritanceFlags="ContainerInherit, ObjectInherit"
$FileSystemAccessRights="FullControl"
$PropagationFlags="None"
$PathType = "Directory"
$CredPath = "*"
$Credentials = Import-CliXml -Path "$CredPath"
$PSDriveName = "*"
#

# Start Script
Import-Module ActiveDirectory

# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

# Start Transcript
Start-Transcript -path $LogLocation

# Verify no PSDrives exist for upcoming operations.
$PSDrive = @(Get-PSDrive)
if (($PSDrive).Name -contains "$PSDriveName") {
    write-host "PSDrive $PSDriveName does exist. Moving on."  
}
else {
    write-host "PSDrive $PSDriveName does not exist! Creating." -ForegroundColor 'White' -BackgroundColor 'DarkBlue'
    New-PSDrive -Name "$PSDriveName" -PSProvider Filesystem -Root $FolderPath -Credential $Credentials
}

# Request Users Name
[string[]] $UserNames = @() -split ","
write-host "Please enter the User's Full Name in format: Full First Name Full Last Name" -BackgroundColor 'DarkGreen' -ForegroundColor 'Black'
write-host "Please enter 1 user's full name per line. Leave field blank and strike enter when finished." -BackgroundColor 'DarkMagenta' -ForegroundColor 'Black'
do {
 $uinput = (Read-Host "Please enter the User's Full Name:")
 
 if ($uinput -ne '') {$UserNames += $uinput}
}
until ($uinput -eq '')

# Get Users SamAccount Name/s
$SAM = @()
$SAM = ForEach ($User in $UserNames) {
    get-aduser -filter "Name -like $('$User')" -Properties DistinguishedName, SamAccountName | Select-Object -Property DistinguishedName, SamAccountName
}

# Create Folder
foreach ($User in $SAM) {
    try {
        $FullPath = -join("$FolderPath", "$($User.SamAccountName)")
        New-Item -Path $FullPath -ItemType $PathType -Force
        write-host "Creating Folder @ $($FullPath)"
        $IdentityReference = $($User.SamAccountName)
        $ACL = Get-ACL $FullPath
        $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule ($IdentityReference,$FileSystemAccessRights,$InheritanceFlags,$PropagationFlags,$AccessControl)
        $ACL.SetAccessRule($AccessRule)
        $ACL | Set-ACL $FullPath
    }
    catch {
        write-host "Error Happened somewhere in this try statement."
    }
}

# Test Path after Creation
foreach ($Path in $FullPath) {
    if (!(Test-Path $Path)) {
        Write-Host "$User path does not exist. Check for errors."
    }
    else {
        Write-Host "All Good."
    }
}

# Complete
Write-Host "Script complete"
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
$CreationTime
Remove-PSDrive -Name $PSDriveName
Stop-Transcript