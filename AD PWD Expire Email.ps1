<#
Send Password Expiry E-Mails
1. Get Users
2. Filter email address from Info
3. Perform magic on data to get correct emails
4. Send emails
Ross Edwardson @ CMI/CORA | 2.21.2022
Rev 1.2
#>

# Varibles
$testing = $true
$logging = $true
$ADServer = "*" # If running cross forests
$CredentialPath = "*.xml" # If running cross forests
$RemoteCredential = Import-CliXml -Path "$CredentialPath" # If running cross forests
$SearchBase = "*"
$ExcludeList = "'New Employees'|'Separated Employees'"   #in the form of "SubOU1|SubOU2|SubOU3" -- possibly needing single quote for OU's with spaces, separate OU's with pipe and double-quote the list.
$smtpServer = "*"
$expireindays = 7 #number of days of soon-to-expire paswords. i.e. notify for expiring in X days (and every day until $negativedays)
$negativedays = -3 #negative number of days (days already-expired). i.e. notify for expired X days ago
$from = "*"
$logNonExpiring = $true
$logFile = "*.csv"
$Transcript = "*.log"
$adminEmailAddr = "*","*","*"
$sampleEmails = 3 #number of sample email to send to adminEmailAddr when testing


# Script Start
# System Settings
Start-Transcript -Path $Transcript -Append
# Start Timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()
$textEncoding = [System.Text.Encoding]::UTF8
$date = Get-Date -format yyyy-MM-dd #for logfile only
$starttime=Get-Date #need time also; don't use date from above

Write-Host "Processing `"$SearchBase`" for Password-Expiration-Notifications"
Write-Host "Testing Mode: $testing"

# Get Users From AD who are Enabled, Passwords Expire
Import-Module ActiveDirectory
Write-Host "Gathering User List"
# $Users = @{}
$users = get-aduser -Server $ADServer -Credential $RemoteCredential -SearchBase $SearchBase -Filter {(enabled -eq $true) -and (passwordNeverExpires -eq $false)} -properties sAMAccountName, displayName, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress, lastLogon, whenCreated, Info
Write-Host "Filtering User List"
$users = $users | Where-Object {$_.DistinguishedName -notmatch $ExcludeList}
$DefaultmaxPasswordAge = (Get-ADDefaultDomainPasswordPolicy -Server $ADServer).MaxPasswordAge

$countprocessed=${users}.Count
$samplesSent=0
$countsent=0
$countnotsent=0
$countfailed=0

#set max sampleEmails to send to $adminEmailAddr
if ( $sampleEmails -isNot [int]) {
    if ( $sampleEmails.ToLower() -eq "all") {
    $sampleEmails=$users.Count
    } #else use the value given
}

if (($testing -eq $true) -and ($sampleEmails -ge 0)) {
    Write-Host "Testing only; $sampleEmails email samples will be sent to $adminEmailAddr"
} elseif (($testing -eq $true) -and ($sampleEmails -eq 0)) {
    Write-Host "Testing only; emails will NOT be sent"
}

# Create CSV Log 
if ($logging -eq $true) {
    #Always purge old CSV file
    Out-File $logfile
    Add-Content $logfile "`"Date`",`"SAMAccountName`",`"DisplayName`",`"Created`",`"PasswordSet`",`"DaystoExpire`",`"ExpiresOn`",`"EmailAddress`",`"Notified`",`"Info`",`"UserSplit`",`"UserFinalEmail`""
}

# Process Each User for Password Expiry
foreach ($user in $users) {
    $UserSplit = $User.info -Split ","
    $UserEmail = $UserSplit | Where-Object {$_ -like '*@*.*'}
    $UserEmailSplit = $UserEmail -split " "
    $UserEFinalFind = $UserEmailSplit | Where-Object {$_ -like '*@*.*'}
    $UserECleanup = $UserEFinalFind -replace '[*]',''
    $UserECleanup2 = $UserECleanup -replace '[;]',''
    $UseremailFinalFinal = $UserECleanup2 -join ", "
    $dName = $user.displayName
    $sName = $user.sAMAccountName
    $emailaddress = $UseremailFinalFinal
    $whencreated = $user.whencreated
    $passwordSetDate = $user.PasswordLastSet
    $sent = "" # Reset Sent Flag
    $Info = $User.Info

    $PasswordPol = (Get-AduserResultantPasswordPolicy -Server $ADServer -Credential $RemoteCredential $user)
    # Check for Fine Grained Password
    if (($PasswordPol) -ne $null) {
        $maxPasswordAge = ($PasswordPol).MaxPasswordAge
    } else {
        # No FGPP set to Domain Default
        $maxPasswordAge = $DefaultmaxPasswordAge
    }

    #If maxPasswordAge=0 then same as passwordNeverExpires, but PasswordCannotExpire bit is not set
    if ($maxPasswordAge -eq 0) {
        Write-Host "$sName MaxPasswordAge = $maxPasswordAge (i.e. PasswordNeverExpires) but bit not set."
    }

    $expiresOn = $passwordsetdate + $maxPasswordAge
    $today = (get-date)

    if ( ($user.passwordexpired -eq $false) -and ($maxPasswordAge -ne 0) ) {   #not Expired and not PasswordNeverExpires
        $daystoexpire = (New-TimeSpan -Start $today -End $expiresOn).Days
    } elseif ( ($user.passwordexpired -eq $true) -and ($passwordSetDate -ne $null) -and ($maxPasswordAge -ne 0) ) {   #if expired and passwordSetDate exists and not PasswordNeverExpires
        # i.e. already expired
        $daystoexpire = -((New-TimeSpan -Start $expiresOn -End $today).Days)
    } else {
        # i.e. (passwordSetDate = never) OR (maxPasswordAge = 0)
        $daystoexpire="NA"
        #continue #"continue" would skip user, but bypass any non-expiry logging
    }

    #Write-Host "$sName DtE: $daystoexpire MPA: $maxPasswordAge" #debug

    # Set verbiage based on Number of Days to Expiry.
    Switch ($daystoexpire) {
        {$_ -ge $negativedays -and $_ -le "-1"} {$messageDays = "has expired"}
        "0" {$messageDays = "will expire today"}
        "1" {$messageDays = "will expire in 1 day"}
        default {$messageDays = "will expire in " + "$daystoexpire" + " days"}
    }

    # Email Subject Set Here
    $subject="Your DRS274 password $messageDays"

    # Email Body Set Here, Note You can use HTML, including Images.
    $body="
    <p>This is a test. This script will trigger if your password expires in 7 days or less.</p>
    <p>Your Active Directory password for your account <b>$sName</b> $messageDays.  After expired, you will not be able to login until your password is changed.</p>
    <p>More info to be placed here.</p>
    Thanks<br>
    Ross' Powershell Script<br>
    </p>
    "

    # If testing-enabled and send-samples, then set recipient to adminEmailAddr else user's EmailAddress
    if (($testing -eq $true) -and ($samplesSent -lt $sampleEmails)) {
        $recipient = $adminEmailAddr
    } else {
        $recipient = $emailaddress
    }

    #if in trigger range, send email
    if ( ($daystoexpire -ge $negativedays) -and ($daystoexpire -lt $expireindays) -and ($daystoexpire -ne "NA") ) {
        # Send Email Message
        if (($emailaddress) -ne $null) {
            if ( ($testing -eq $false) -or (($testing -eq $true) -and ($samplesSent -lt $sampleEmails)) ) {
                try {
                    Send-Mailmessage -smtpServer $smtpServer -from $from -to $recipient -subject $subject -body $body -bodyasHTML -priority High -Encoding $textEncoding -ErrorAction Stop -ErrorVariable err
                } catch {
                    write-host "Error: Could not send email to $recipient via $smtpServer"
                    $sent = "Send fail"
                    $countfailed++
                } finally {
                    if ($err.Count -eq 0) {
                        write-host "Sent email for $sName to $recipient"
                        $countsent++
                        if ($testing -eq $true) {
                            $samplesSent++
                            $sent = "toAdmin"
                        } else { $sent = "Yes" }
                    }
                }
            } else {
                Write-Host "Testing mode: skipping email to $recipient"
                $sent = "No"
                $countnotsent++
            }
        } else {
            Write-Host "$dName ($sName) has no email address."
            $sent = "No addr"
            $countnotsent++
        }

        # If Logging is Enabled Log Details
        if ($logging -eq $true) {
            Add-Content $logfile "`"$date`",`"$sName`",`"$dName`",`"$whencreated`",`"$passwordSetDate`",`"$daystoExpire`",`"$expireson`",`"$emailaddress`",`"$sent`",`"$Info`",`"$UserSplit`",`"$UserEFinalFind`""
        }
    } else {
        #if ( ($daystoexpire -eq "NA") -and ($maxPasswordAge -eq 0) ) { Write-Host "$sName PasswordNeverExpires" } elseif ($daystoexpire -eq "NA") { Write-Host "$sName PasswordNeverSet" } #debug
        # Log Non Expiring Password
        if ( ($logging -eq $true) -and ($logNonExpiring -eq $true) ) {
            if ($maxPasswordAge -eq 0 ) {
                $sent = "NeverExp"
            } else {
                $sent = "No"
            }
            Add-Content $logfile "`"$date`",`"$sName`",`"$dName`",`"$whencreated`",`"$passwordSetDate`",`"$daystoExpire`",`"$expireson`",`"$emailaddress`",`"$sent`",`"$Info`",`"$UserSplit`",`"$UserEFinalFind`""
        }
    }

} # End User Processing

$endtime=Get-Date
$totaltime=($endtime-$starttime).TotalSeconds
$minutes="{0:N0}" -f ($totaltime/60)
$seconds="{0:N0}" -f ($totaltime%60)

Write-Host "$countprocessed Users from `"$SearchBase`" Processed in $minutes minutes $seconds seconds."
Write-Host "Email trigger range from $negativedays (past) to $expireindays (upcoming) days of user's password expiry date."
Write-Host "$countsent Emails Sent."
Write-Host "$countnotsent Emails skipped."
Write-Host "$countfailed Emails failed."

# sort the CSV file
if ($logging -eq $true) {
    Rename-Item $logfile "$logfile.old"
    import-csv "$logfile.old" | sort ExpiresOn | export-csv $logfile -NoTypeInformation
    Remove-Item "$logFile.old"
    Write-Host "CSV File created at ${logfile}."

    if ($testing -eq $true) {
        $body="<b><i>Testing Mode.</i></b><br>"
    } else {
        $body=""
    }

    $body+="
    CSV Attached for $date<br>
    $countprocessed Users from `"$SearchBase`" Processed in $minutes minutes $seconds seconds.<br>
    Email trigger range from $negativedays (past) to $expireindays (upcoming) days of user's password expiry date.<br>
    $countsent Emails Sent.<br>
    $countnotsent Emails skipped.<br>
    $countfailed Emails failed.
    "


    try {
        Send-Mailmessage -smtpServer $smtpServer -from $from -to $adminEmailAddr -subject "Password Expiry Logs" -body $body -bodyasHTML -Attachments "$logFile" -priority High -Encoding $textEncoding -ErrorAction Stop -ErrorVariable err
    } catch {
         write-host "Error: Failed to email CSV log to $adminEmailAddr via $smtpServer"
    } finally {
        if ($err.Count -eq 0) {
            write-host "CSV emailed to $adminEmailAddr"
        }
    }
}

# End
Write-Host "Script complete"
$Now3 = Get-Date -Format "dddd MM/dd/yyyy HH:mm"
Write-Host "$Now3"
$StopWatch.Stop()
$CreationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)
Write-Host "I took $CreationTime to complete."
Stop-Transcript