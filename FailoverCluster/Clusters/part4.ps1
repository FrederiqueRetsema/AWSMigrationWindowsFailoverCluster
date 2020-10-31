# Cluster install script - part 4
# ===============================

$LOGFILE                                       = "C:\Install\install_log.txt"
$PASSWORDSFILE                                 = "C:\Install\uidspwds.ps1"
$CHANGE_USERNAME_OF_AWSSERVICE_POWERSHELL_FILE = "C:\Install\ChangeUsernameOfAWSService.ps1"

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

# Set-W3SVCService
# ----------------
function Set-W3SVCService {

  stop-service -Name w3svc
  Set-Service -Name w3svc -StartupType Manual
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

# Main Program
# ============

Write-Log -LogText "START part4.ps1"
Write-Log -LogText "TRACE Get passwords"
. $PASSWORDSFILE

Write-Log -LogText "TRACE Remove current startup job for install"
Unregister-ScheduledTask -TaskName Part4 -Confirm:$false
Remove-ScheduledTaskAtStartup -TaskName "Part4" 

Write-Log -LogText "TRACE Configure W3SVC Service"
Set-W3SVCService

write-log -LogText "TRACE Change username of AWS Service"
. $CHANGE_USERNAME_OF_AWSSERVICE_POWERSHELL_FILE

Write-Log -LogText "TRACE Create new scheduled task for creating a new webpage every second (will run forever)"
New-ScheduledTaskAtStartup -ScriptName "C:\Install\CreateWebpage.ps1" -TaskName "create-webpage" -WorkingDirectory "C:\Install" -UserID $LocalAdminID -Password $LocalAdminPwd

Write-Log -LogText "TRACE Create new scheduled task for next shell script"
New-ScheduledTaskAtStartup -ScriptName "C:\Install\part5.ps1" -TaskName "Part5" -WorkingDirectory "C:\Install" -UserID $LocalAdminID -Password $LocalAdminPwd

Write-Log -LogText "TRACE enforce reboot"
Write-Log -LogText "CHECK start part5.ps1 in 2 minutes"
Write-Log -LogText "CHECK start CreateWebpage.ps1 in 2 minutes"
Write-Log -LogText "END part4.ps1"

# Wait for 10 seconds to be sure the data is sent to CloudWatch before the reboot starts
Start-Sleep -Seconds 10

Restart-Computer -Force
