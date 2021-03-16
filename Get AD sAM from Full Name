<#
Find sAMAccountName based off users first and last name.
Single Column. "User" as header in Excel with "First Last" convention.
Ross Edwardson @ CMI/CORA | 03/05/2021
#>

#Variables

$UserList = Import-Csv '*\List2.csv'
$OutFile = "*\export1.csv"

#Start Script

#Get Account Name
foreach ($User in $UserList)
{
    $domainname = $user.user
Get-ADUser -Filter{displayName -like $domainname} | select-object samAccountName | Export-Csv -Path $OutFile -NoType -Append
}
