<#
Query number of CPUs and Cores per Host
Query number of CPUS, Cores, and Memory per VM
Ross Edwardson @ CMI/CORA - 03/16/2021
#>

#Variables
$result = @()
$result1 = @()
$vCenter = "*"
$FolderPath = 'C:\Script Output\'
$LogPath = "C:\Script Output\log.log"
$CredentialPath = "*.xml"
$RemoteCredential = Import-CliXml -Path "$CredentialPath"


# Script Start
# Start Transcript
Start-Transcript -Path $LogPath

# Create Output File Name - Hosts
$FileSuffix = (get-date).toString('yyyyMMddHHmm')
$BackupPath = $FolderPath + "Stats" + "_" + "$vCenter" + "_" + $FileSuffix + ".csv"
$BackupFile = "Stats" + "_" + "$vCenter" + "_" + $FileSuffix + ".csv"
New-Item -ItemType "File" -Path $FolderPath -Name "$BackupFile" -force
write-host "Output file written to : $BackupPath"

# Create Output File Name - VMs
$FileSuffix1 = (get-date).toString('yyyyMMddHHmm')
$BackupPathVMs = $FolderPath + "Stats" + "_" + "VMs" + "_" + "$vCenter" + "_" + $FileSuffix1 + ".csv"
$BackupFile1 = "Stats" + "_" + "VMs" + "_" + "$vCenter" + "_" + $FileSuffix1 + ".csv"
New-Item -ItemType "File" -Path $FolderPath -Name "$BackupFile1" -force
write-host "Output file written to : $BackupPathVM"

# Connect to VIServer
Connect-VIServer $vCenter -Credential ($RemoteCredential)

# Get Hosts
$ESXHosts = Get-View -ViewType HostSystem
foreach ($ESXHost in $ESXHosts) {
    $obj = new-object psobject 
    $obj | Add-Member -MemberType NoteProperty -Name name -Value $ESXHost.Name 
    $obj | Add-Member -MemberType NoteProperty -Name CPUSocket -Value $ESXHost.hardware.CpuInfo.NumCpuPackages 
    $obj | Add-Member -MemberType NoteProperty -Name Corepersocket -Value $ESXHost.hardware.CpuInfo.NumCpuCores 
    $obj | Add-Member -MemberType NoteProperty -Name TotalCores -Value ($ESXHost.hardware.CpuInfo.NumCpuPackages * $EsxHost.hardware.CpuInfo.NumCpuCores)
    $obj | Add-Member -MemberType NoteProperty -Name Memory -Value $ESXHost.hardware.MemoryMB
    $result += $obj 
}

# Get VMs
$vms = Get-View -ViewType VirtualMachine
foreach ($vm in $vms) {
    $obj1 = New-Object PSObject
    $obj1 | Add-Member -MemberType NoteProperty -Name Host -Value $vm.summary.runtime.host
    $obj1 | Add-Member -MemberType NoteProperty -Name Name -Value $vm.Name
    $obj1 | Add-Member -MemberType NoteProperty -Name vCPUs -Value $vm.config.hardware.NumCPU
    $obj1 | Add-Member -MemberType NoteProperty -Name vSockets -Value ($vm.config.hardware.NumCPU/$vm.config.hardware.NumCoresPerSocket)
    $obj1 | Add-Member -MemberType NoteProperty -Name Persocket -Value $vm.config.hardware.NumCoresPerSocket -Force
    $obj1 | Add-Member -MemberType NoteProperty -Name Memory -Value $vm.config.hardware.MemoryMB
    $result1 += $obj1
}

# Export the data
$result | Export-CSV $BackupPath -NoTypeInformation 
$result1 | Export-CSV $BackupPathVMs -NoTypeInformation

# Complete
Disconnect-viserver * -Confirm:$false
Stop-Transcript
