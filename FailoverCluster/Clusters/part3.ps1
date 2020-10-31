# Cluster install script - part 3
# ===============================

$LOGFILE       = "C:\Install\install_log.txt"
$PASSWORDSFILE = "C:\Install\uidspwds.ps1"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${env:COMPUTERNAME} ${CurrentTime} - $LogText" >> $LOGFILE
}

# Remove-ScheduledTaskAtStartup
# -----------------------------
function Remove-ScheduledTaskAtStartup {
  param([String] $TaskName)

  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# New-ScheduledTaskAtStartup
# --------------------------
function New-ScheduledTaskAtStartup {
  param([String] $ScriptName,
        [String] $TaskName,
        [String] $WorkingDirectory,
        [String] $UserID,
        [String] $Password)

  $Action  = New-ScheduledTaskAction -Execute PowerShell.exe -WorkingDirectory "${WorkingDirectory}" -Argument "-File ${ScriptName}"
  $Trigger = New-ScheduledTaskTrigger -AtStartup
  Register-ScheduledTask -TaskName "${TaskName}" -Action $Action -Trigger $Trigger -User "${UserID}" -Password "${LocalAdminPwd}"
}

# Install-WindowsFeaturesForCluster
# ---------------------------------
function Install-WindowsFeaturesForCluster {
  
  Install-Windowsfeature -IncludeManagementTools Failover-Clustering,Web-Server
}

# Main Program 
# ============

Write-Log -LogText "START part3.ps1"

Write-Log -LogText "TRACE Get passwords"
. $PASSWORDSFILE

Write-Log -LogText "TRACE Remove current startup job for install"
Remove-ScheduledTaskAtStartup -TaskName "Part3"

Write-Log -LogText "TRACE Create new scheduled task"
New-ScheduledTaskAtStartup -ScriptName "C:\Install\part4.ps1" -TaskName "Part4" -WorkingDirectory "C:\Install" -UserID $LocalAdminID -Password $LocalAdminPwd

Write-Log -LogText "TRACE Install Windowsfeatures for cluster"
Install-WindowsFeaturesForCluster 

# For the Failover Cluster windows feature, a reboot is needed
Write-Log -LogText "TRACE Enforce reboot"
Write-Log -LogText "CHECK start part4.ps1 in 2 minutes"
Write-Log -LogText "END part3.ps1"

# Wait for 10 seconds to be sure the data is sent to CloudWatch before the reboot starts
Start-Sleep -Seconds 10

Restart-Computer -Force
