# Cluster install script - part 1
# ===============================

param(
   [Parameter(Mandatory=$true)] [String] $ComputerName
)

$LOGFILE = "C:\Install\install_log.txt"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${CurrentTime} - $LogText" >> $LOGFILE
}

# Set-LocalAdminPassword 
# -------------------------
function Set-LocalAdminPassword {
  param([String] $Password)

  $SecureLocalAdminPwd = ConvertTo-SecureString -String $Password -AsPlainText -Force
  Set-LocalUser -Name "Administrator" -Password $SecureLocalAdminPwd  
}

# Create-ScheduledTaskAtStartup
# -----------------------------
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

# Rename-ComputerIfNeeded
# -----------------------
function Rename-ComputerIfNecessary {
  param([String] $ComputerName)

  if ("$env:computername" -ne "$ComputerName") {
  	Rename-Computer -NewName "$ComputerName"
  }
}

# Main Program
# ============

Write-Log -LogText "START part1.ps1"
Write-Log -LogText "TRACE Get passwords"
. c:\install\uidspwds.ps1

# Update local admin password. This is needed for scheduled tasks in the futute

Write-Log -LogText "TRACE Change local admin password"
Set-LocalAdminPassword -Password $LocalAdminPwd

Write-Log -LogText "TRACE Create new scheduled task"
New-ScheduledTaskAtStartup -ScriptName "C:\Install\part2.ps1" -TaskName "Part2" -WorkingDirectory "C:\Install" -UserID "Administrator" -Password $LocalAdminPwd

Write-Log -LogText "Rename computer if needed"
Rename-ComputerIfNecessary -ComputerName $ComputerName

Write-Log -LogText "TRACE Enforce reboot"
Write-Log -LogText "END part1.ps1"
Restart-Computer -Force
