# This script when run from a scheduled task upon start of the system will continually run and ping 
# a list of computers to determine if they are available.  
# Systems that are reported down, then come back up, will in the next cycle be alerted that they are back online.

$computers = get-content C:\pathto\pingnodes.txt # List of computers to ping
$emailFrom = "FromEmail@yourdomain.com" # Email address to send notification from
$emailTo = "ToEmail@yourdomain.com" # Email address to send notification to
$unresponsive = @() # Initialize empty array to store previously unresponsive computers

while ($true) { # Loop continuously
    $failed = @() # Initialize empty array to store failed computers
    $responded = @() # Initialize empty array to store previously unresponsive computers that have now responded
    
    foreach ($computer in $computers) {
        if (!(Test-Connection -ComputerName $computer -Count 1 -ErrorAction SilentlyContinue)) {
            $failed += $computer # Add failed computer to the array
        }
        elseif ($unresponsive -contains $computer) {
            $responded += $computer # Add previously unresponsive computer to the array
        }
    }
     
    $body = "Pinging the following computers:`n`n$($computers -join "`n")`n`n"
    
    if ($failed) { # If there are failed computers
        $body += "This script pings every 10 minutes a list of systems found in \\server\share\pingnodes.txt.  It is run as a scheduled task that launches upon system startup.  The following systems are NOT responding:`n`n$($failed -join "`n")"
        $smtpServer = "yourSMTPserver.com"
        $messageParams = @{
            To = $emailTo
            From = $emailFrom
            Subject = "Computer(s) not responding"
            Body = $body
            SmtpServer = $smtpServer
        }
        Send-MailMessage @messageParams
    }
    
    if ($responded) { # If there are previously unresponsive computers that have now responded
        $body = "The following computers have come back online:`n`n$($responded -join "`n")"
        $smtpServer = "YourSMTPServer.com"
        $messageParams = @{
            To = $emailTo
            From = $emailFrom
            Subject = "Computer(s) back online"
            Body = $body
            SmtpServer = $smtpServer
        }
        Send-MailMessage @messageParams
        $unresponsive = $unresponsive | Where-Object { $_ -notin $responded } # Remove previously unresponsive computers that have now responded
    }
    
    if ($failed -or $unresponsive) { # If there are failed computers or previously unresponsive computers
        $unresponsive += $failed # Add currently unresponsive computers to the array of previously unresponsive computers
        $unresponsive = $unresponsive | Select-Object -Unique # Remove duplicates
    }
    
    Start-Sleep -Seconds 600 # Wait for 10 minutes before pinging again
}
