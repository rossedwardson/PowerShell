<#
Allow Nuance through firewall.
1. Get logged in user
2. Get logged in users Nuance Folder
3. Add Nuance Path to firewall allow
Ross Edwardson @ CMI/CORA | 09.09.2021
#>

# Variables
$DisplayName = "Allow Nuance PSOne"
$Directon = "Inbound"
$NetProfile = "Any"
$Action = "Allow"

# Script Start
 
# Get Local logged in user
$User = ((Get-CimInstance -Class Win32_ComputerSystem).Username).Split('\')[1]

# Build Variable for Path
$Path = "C:\Users\$User\AppData\Local\Apps\2.0\"

# Get Users Nuance Folder
$FullPath = Get-ChildItem -path $Path -Recurse -include "Nuance.PowerScribeOne.exe"

# Add Nuance to Firewall
New-NetFirewallRule -DisplayName "$DisplayName" -Direction "$Directon" -Program "$FullPath" -Profile "$NetProfile" -Action "$Action"
