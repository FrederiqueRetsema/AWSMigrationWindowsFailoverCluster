# Cluster install script - part 4
# ===============================

$LOGFILE    = "C:\Install\install_log.txt"
$CLUSTERDIR = "C:\ClusterScripts"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${CurrentTime} - $LogText" >> $LOGFILE
}

# Set-W3SVCService
# ----------------
function Set-W3SVCService {

  stop-service -Name w3svc
  Set-Service -Name w3svc -StartupType Manual

}

# Move-ClusterConfigFiles
# -----------------------
function Move-ClusterConfigFiles {
  param([String] $ToNewDir)

  mkdir $ToNewDir
  Move-Item cluster*.ps1 $ToNewDir
  Move-Item myclusteriis-entrypoints.vbs $ToNewDir
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
. .\uidspwds.ps1

Write-Log -LogText "TRACE Remove current startup job for install"
Unregister-ScheduledTask -TaskName Part4 -Confirm:$false

Write-Log -LogText "TRACE Configure W3SVC Service"
Set-W3SVCService

Write-Log -LogText "TRACE Move cluster config files to new directory ${CLUSTERDIR}"
Move-ClusterConfigFiles -ToNewDir $CLUSTERDIR

write-log -LogText "TRACE Create new scheduled task for creating a new webpage every second (will run forever)"
New-ScheduledTaskAtStartup -ScriptName "C:\Install\create-webpage.ps1" -TaskName "create-webpage" -WorkingDirectory "C:\Install" -UserID "Administrator" -Password $LocalAdminPwd

# Reboot is needed, because of scheduled task for creating a new webpage every second
write-log -LogText "TRACE enforce reboot"
write-log -LogText "END part4.ps1"
Restart-Computer -Force
