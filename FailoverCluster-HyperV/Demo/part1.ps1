# Part 1 of the DC installation
# =============================

$COMPUTERNAME = "Demo"
$LOGFILE      = "C:\Install\install_log.txt"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${CurrentTime} - ${LogText}" >> $LOGFILE
}

# Set-LocalAdminPassword
# ----------------------
function Set-LocalAdministratorPassword {
  param([String] $Password)

  $SecureLocalAdminPwd = ConvertTo-SecureString -String $Password -AsPlainText -Force
  Set-LocalUser -Name "Administrator" -Password $SecureLocalAdminPwd
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

# Rename-ComputerIfNecessary
# --------------------------
function Rename-ComputerIfNecessary {
  param([String] $ComputerName)

  if ("$env:computername" -ne "$ComputerName") {
	Rename-Computer -NewName "$ComputerName"
  }
}

# Main Program
# ============

Write-Log -LogText "START C:\Install\part1.ps1"

Write-Log -LogText "TRACE Get passwords"
. c:\install\uidspwds.ps1

# Set local admin password is needed for creating the scheduled task

Write-Log -LogText "TRACE Set local admin password"
Set-LocalAdministratorPassword -Password $LocalAdminPwd

write-log -LogText "TRACE Create new scheduled task"
New-ScheduledTaskAtStartup -ScriptName "C:\Install\part2.ps1" -TaskName "Part2" -WorkingDirectory "C:\Install" -UserID "Administrator" -Password $LocalAdminPwd

write-log($logtext="Rename computer")
Rename-ComputerIfNecessary -ComputerName $COMPUTERNAME

Write-Log -LogText "TRACE Enforce reboot"
Write-Log -LogText "END C:\Install\part1.ps1"
Restart-Computer -Force
