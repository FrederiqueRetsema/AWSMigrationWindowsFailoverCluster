# ASGNode - part 2
# ================

$LOGFILE       = "C:\Install\install_log.txt"
$PASSWORDSFILE = "C:\Install\uidspwds.ps1"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = get-date -UFormat %H:%M:%S
  Write-Output "${env:COMPUTERNAME} ${CurrentTime} - $LogText" >> $LOGFILE
}

# Remove-ScheduledTaskAtStartup
# -----------------------------
function Remove-ScheduledTaskAtStartup {
  param([String] $TaskName)

  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Main Program
# ============

# Wait 2 seconds to prevent a write to the log on the same moment as the create-website.ps1 will write it's line to the same log
Start-Sleep -Seconds 2

Write-Log -LogText "START part2.ps1"

Write-Log -LogText "TRACE Remove current startup job for install"
Remove-ScheduledTaskAtStartup -TaskName "Part2"

Write-Log -LogText "TRACE Ready, send signal"
Write-Log -LogText "END part2.ps1"

# A cfn-signal (no reboot) will be added under here by userdata in the cloudformation template