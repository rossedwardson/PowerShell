<# 
Create Encrypted Password for use in Powershell - Rev 1.1
Ross Edwardson | 03/04/2021
  To use in script add the following:
  # Variables
  $OutFile = "*\SavedCreds_${env:USERNAME}_${env:COMPUTERNAME}.xml"

  # Place this line in script to extract username and password
  $UserCredential = Import-CliXml -Path $OutFile
#>

#Variables

$UserCredential = Get-Credential
$OutFile = "*\SavedCreds_${env:USERNAME}_${env:COMPUTERNAME}.xml"

#Start Script

#Create Password

$UserCredential | Export-CliXml -Path $OutFile
