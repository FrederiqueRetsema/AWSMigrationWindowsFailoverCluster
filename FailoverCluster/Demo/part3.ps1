# Demo install script - part 3
# ============================

$LOGFILE          = "C:\Install\install_log.txt"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${env:COMPUTERNAME} ${CurrentTime} - $LogText" >> $LOGFILE
}

# Remove-ScheduledTask
# --------------------
function Remove-ScheduledTask {
  param([String] $TaskName)

  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false

}

# Main Program
# ============

Write-Log -LogText "START part3.ps1"

Write-Log -LogText "TRACE Remove current job"
Remove-ScheduledTask -TaskName "Part3"

Write-Log -LogText "TRACE Ready, send signal"
Write-Log -LogText "END part3.ps1"

# cfn-signal will be added here by userdata
#
