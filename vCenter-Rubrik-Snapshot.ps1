<#
Shutdown and Power On VM using vCenter's API's & Take Snapshot using Rubrik's API during power off state
1. Token vCenter
2. Token Rubrik
3. Get VM's Number in vCenter
4. Power Off VM vCenter API
5. Get VM in Rubrik
6. Take Snapshot
7. Power on VM vCenter
8. Query SLA Domains
9. Assign SLA to Snapshot
Ross Edwardson @ CMI/CORA | 09.23.2021
Rev 1.9 | 12.23.2021
#>

# Variables
$vCenter = "*"
$RubrikCluster = "*"
$CredentialPath = "*.xml"
$RubrikCredentialPath = "*.xml"
$LogDirectory = "*\Logs"
$WantedVMName = "*" # VM to run actions against
$WantedSLAName = "*" # SLA to assign to above VM

# Script Start
# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

# Checking log path exists, if not trying to create it
$LogFilePathTest = Test-Path $LogDirectory

# Creating if false
IF ($LogFilePathTest -eq $False) {
    New-Item -Path $LogDirectory -ItemType "Directory"
}

# Getting time
$Now = Get-Date

# Creating log file name
$Log = $LogDirectory + "\" + "$WantedVMName" + "_" + $Now.ToString("yyyy-MM-dd") + "@" + $Now.ToString("HH-mm-ss") + ".log"

# Starting logging
Start-Transcript -Path $Log -NoClobber

# Import Modules
Import-Module Rubrik

# Adding certificate exception and TLS 1.2 to prevent API errors
Add-Type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

#######################
## vCenter API Login ##
#######################

# Import vCenter Credentials
$VCredential = Import-CliXml -Path "$CredentialPath"

# Setting credentials
$vCUser = $vCredential.UserName
$vCPassword = $vCredential.GetNetworkCredential().Password

# Building vCenter API string
$vCv1BaseURL = "https://" + $vCenter + "/rest/com/vmware/cis/"
$vCSessionURL = $vCv1BaseURL + "session"
$vCHeader = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($vCUser+":"+$vCPassword))}

# Authenticating with vCenter API
Try {
    $vCSessionResponse = Invoke-WebRequest -Uri $vCSessionURL -Method 'POST' -Headers $vCHeader

    # Extracting the token from the JSON response
    $vCToken = (ConvertFrom-Json $vCSessionResponse.Content).value

    # Setting Token to Session Var
    $vCSession = @{'vmware-api-session-id' = $vCToken}
    Write-Host "Auth'd to vCenter using"$vCToken"." -BackgroundColor 'DarkGreen' -ForegroundColor 'Black'
}
Catch {
    $ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
    Write-Host "Error in vCenter API."
    Break
}

######################
## Rubrik API Login ##
######################

# Login to Rubrik via API
# Import Rubrik Credentials
$RubrikCredential = Import-CliXml -Path "$RubrikCredentialPath"

# Setting credentials
$RubrikUser = $RubrikCredential.UserName
$RubrikPassword = $RubrikCredential.GetNetworkCredential().Password

# Building Rubrik API string & invoking REST API
$v1BaseURL = "https://" + $RubrikCluster + "/api/v1/"
$v2BaseURL = "https://" + $RubrikCluster + "/api/v2/"
# $InternalURL = "https://" + $RubrikCluster + "/api/internal/"# Not Needed ATM
$RubrikSessionURL = $v1BaseURL + "session"
$Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($RubrikUser+":"+$RubrikPassword))}
$Type = "application/json"

# Authenticating with API
Try {
    $RubrikSessionResponse = Invoke-RestMethod -Uri $RubrikSessionURL -Headers $Header -Method 'POST' -ContentType $Type
    
    # Extracting the token from the JSON response
    $RubrikSessionHeader = @{'Authorization' = "Bearer $($RubrikSessionResponse.token)"}
    Write-Host "Auth'd to Rubrik using Rubrik_SVC." -BackgroundColor 'DarkMagenta' -ForegroundColor 'Black'
        
        # Append URI for Cluster Info Test
        $ClusterInfoURL = $v1BaseURL+"cluster/me"
            
            # Get Cluster Info
            Try {
                $ClusterInfo = Invoke-RestMethod -Uri $ClusterInfoURL -TimeoutSec 60 -Headers $RubrikSessionHeader -ContentType $Type
                Write-Host "Connected to $ClusterInfo.Name"
            }
            Catch{
                $ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
                Write-Host "Error in Rubrik Cluster Test." -BackgroundColor 'DarkCyan' -ForegroundColor 'Black'
                Break
            }
}
Catch {
    $ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
    Write-Host "Error in Rubrik API."
    Break
}

#########################
## VM Operations Start ##
#########################

# Build URI for upcoming operations
$VCURI = "https://" + $vCenter + "/rest/vcenter/vm/"

# List VM and Get VM
Try {
    $R1 = Invoke-WebRequest -Uri "$VCURI" -Method 'Get' -Headers $vCSession
    $vCenterVMs = (ConvertFrom-Json $R1.Content).value

        # Filter for Rubrik-Autotest
        $RubrikVM = ($vCenterVMs | Where-Object {$_.name -eq "$WantedVMName"}).Vm
        $RubrikVM
}
Catch {
    $ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
    Write-Host "Error in vCenter VM List & Get."
}

# Get VM Powerstate Pre-Shut
    # Append URI for VM
    $VMURI = "https://" + $vCenter + "/rest/vcenter/vm/" + "$RubrikVM" + "/power"

    # Power State Request
    Try {
        $R2 = Invoke-WebRequest -URI "$VMURI" -Method 'Get' -Headers $vCSession
    }
    Catch {
        $ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
        Write-Host "Error in Power State Request."
        Break
    }
        
# Save State to Variable
$PowerStatePre = (ConvertFrom-Json $R2.Content).value

# If powerstate = on power off. If powerstate off continue to Snap
If ($PowerStatePre.State -eq "POWERED_ON") {
    Write-Host "VM is on. Proceeding to power off."
             
        # Append URI for Power Post
        $VMURIPower = "https://" + $vCenter + "/rest/vcenter/vm/" + "$RubrikVM" + "/guest/power?action=shutdown"
            
            # Run Stop Action
                Try {
                    $R3 = Invoke-WebRequest -URI "$VMURIPower" -Method 'Post' -Headers $vCSession
                    Write-Host "Shutting down guest OS"
                }
                Catch {
                    $ErrorMessage = $_.ErrorDetails; "Error: $ErrorMessage"
                    Write-Host "Error in Stop Action."
                    Break
                }
            }
    Else {
        write-host "VM is already powered off. Continuing to Snapshot Action."
    }

# Loop until VM power is off
do { 
    # Get VM Powerstate Pre-Shut
    # Power State Request
    Try {
        $R4 = Invoke-WebRequest -URI "$VMURI" -Method 'Get' -Headers $vCSession
        
        # Sleep for 10 seconds Per loop
        Start-Sleep -s "10"
        Write-Host "Sleeping for 10 seconds til VM is off"
    }
    Catch {
        $ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
        Write-Host "Error in power state loop request"
        Break
    }
        # Save R4 to Variable
        $PowerStatePost = (ConvertFrom-Json $R4.Content).value
}
until ($PowerStatePost.State -eq 'POWERED_OFF')
Write-Host "Moving on to snapshot section"

# Get VM info from Rubrik
    # Append URI for Get VM
    $RubrikURIGet = "https://" + $RubrikCluster + "/api/v1/vmware/vm?" + "name=$WantedVMName"

    # Get VM request
    Try {
        $R5 = Invoke-WebRequest "$RubrikURIGet" -Method 'GET' -Headers $RubrikSessionHeader
    }
    Catch {
        $ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
        Write-Host "Error in Rubrik get vm request."
        Break
    }

# Save VM JSON to variables
$R5A = (ConvertFrom-Json $R5.Content).Data
$R5VM = $R5A.ID
$R5VMName = $R5A.name

# Start On-Demand Backup
    # Append URI for Snapshot
    $SnapURI = "https://" + $RubrikCluster + "/api/v1/vmware/vm/" + $R5VM + "/snapshot"

    # Take snapshot
    Try {
        $R6 = Invoke-WebRequest "$SnapURI" -Method 'POST' -Headers $RubrikSessionHeader
        Write-Host "Snapshot taken for $R5VMName"
    }
    Catch {
        $ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
        Write-Host "Error in Rubrik take snapshot."
        Break
    }
# Save snapshot ref to variable
$R6Status = (ConvertFrom-Json $R6.Content)
$R6ID = $R6Status.ID

# Get Latest Events to tie to job id & loop til job completes
    # Append URI for latest events with limit of 10 events and only backup jobs
    $JobIDURI = "https://" + $RubrikCluster + "/api/v1/event/" + "latest?limit=10" + "&event_type=Backup" + "&object_name=$WantedVMName"
Do {
    Try {
        $R7 = Invoke-WebRequest $JobIDURI -Method 'GET' -Headers $RubrikSessionHeader
            # Sleep for 10 seconds Per loop
            Start-Sleep -s "10"
            Write-Host "Sleeping for 10 seconds til Snapshot is done."
    }
    Catch {
        $ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
        Write-Host "Error in Rubrik get snap status."
        Break
    }
    # Get true ID from events
    $R7ID = (ConvertFrom-Json $R7.Content).Data
    $R7Job = $R7ID.LatestEvent
    $JobFilter = ($R7Job | Where-Object {$_.jobinstanceid -like "$R6ID"})
    # $JobID = $JobFilter.id # Unneeded, but keeping for reasons.
    $JobState = $JobFilter.EventStatus
}
Until ($JobState -eq 'Success')
Write-Host "Snapshot for $WantedVMName is complete. Powering VM on."

# Get VM Powerstate Post Snapshot
Try {
    $R8 = Invoke-WebRequest -URI "$VMURI" -Method 'Get' -Headers $vCSession
}
Catch {
    $ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
    Write-Host "Error in Power State Request."
    Break
}
        
# Save State to Variable
$PowerStatePostSnap = (ConvertFrom-Json $R8.Content).value

# Power VM on
If ($PowerStatePostSnap.State -eq "POWERED_OFF") {
    Write-Host "VM is off. Proceeding to power on."
             
        # Append URI for Power On
        $VMURIPowerOn = "https://" + $vCenter + "/rest/vcenter/vm/" + "$RubrikVM" + "/power/start"
            
            # Run Start Action
                Try {
                    $R9 = Invoke-WebRequest -URI "$VMURIPowerOn" -Method 'Post' -Headers $vCSession
                    Write-Host "Powering on $WantedVMName"
                }
                Catch {
                    $ErrorMessage = $_.ErrorDetails; "Error: $ErrorMessage"
                    Write-Host "Error in Power On Action."
                    Break
                }
            }
    Else {
        write-host "VM is already powered on. Check for errors in script."
    }

# Verify Power is on
Try {
    $R10 = Invoke-WebRequest -URI "$VMURI" -Method 'Get' -Headers $vCSession
}
Catch {
    $ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
    Write-Host "Error in Power State Request."
    Break
}
$PostState = (ConvertFrom-Json $R10.Content).value
Write-Host "$WantedVMName is $PostState"

# Assign SLA to snapshot
    # Query all SLAs
    # Append URI for upcoming query
    $QURI = $v2BaseURL + "sla_domain"

    # Get all SLAs
    $R11 = Invoke-WebRequest -URI $QURI -Method 'GET' -Headers $RubrikSessionHeader

    # Filter for Wanted SLA
    $R11SLA = (ConvertFrom-Json $R11.Content).Data
    $SLA = ($R11SLA | Where-Object {$_.name -like $WantedSLAName})
    $WantedSLAID = $SLA.id

# Apply SLA to Snap from Request 7
    # Append URI for Snap Apply
    $AssignSLADomainURL = $v2BaseURL + "sla_domain/" + $WantedSLAID + "/assign"

    # Creating JSON body
    $SLADomainJSON = "{
        ""managedIds"": [""$R5VM""]
    }"

    # Assign SLA
    Try {
        $AssignSLADomain = Invoke-RestMethod -Method POST -Uri $AssignSLADomainURL -Body $SLADomainJSON -TimeoutSec 100 -Headers $RubrikSessionHeader -ContentType $Type
        $AssignSLADomain
        $ProtectionJob = "SUCCESS"
    }
    Catch {
        $ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
        $ProtectionJob = "FAIL"
        Write-Host "Error happened in applying SLA"
    }
Write-Host "Task: Assign $WantedSLAName to"$WantedVMName" = $ProtectionJob. "

# Complete
Write-Host "Script complete"
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
Write-Host "I took $CreationTime to complete."
Stop-Transcript