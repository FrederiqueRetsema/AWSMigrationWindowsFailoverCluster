# Cluster1 install script
# =======================

$LOGFILE          = "C:\Install\install_log.txt"
$COMPUTERNAMEFILE = "C:\Install\computername.ps1"
$PASSWORDSFILE    = "C:\Install\uidspwds.ps1"

# Write-Log
# ---------
# ComputerName is normally determined from the $env:ComputerName, but on EC2 this is
# within this script an EC2-name. This routine therefore needs an extra parameter.
# After running this script and a reboot (f.e. in part2.ps1, Configure-NetworkCards.ps1 etc) 
# this isn't a problem anymore because the computername is changed then.
function Write-Log {
  param([String] $ComputerName,
        [String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${ComputerName} ${CurrentTime} - $LogText" >> $LOGFILE
}

# Set-LocalAdminPassword 
# -------------------------
function Set-LocalAdminPassword {
  param([String] $UserID,
        [String] $Password)

  $SecureLocalAdminPwd = ConvertTo-SecureString -String $Password -AsPlainText -Force
  Set-LocalUser -Name $UserID -Password $SecureLocalAdminPwd
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
  Register-ScheduledTask -TaskName "${TaskName}" -Action $Action -Trigger $Trigger -User "${UserID}" -Password "${Password}"
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

# Get the computername. Should be done before all other commands and without trace line, to prevent confusion in the log file
. $COMPUTERNAMEFILE

Write-Log -ComputerName $COMPUTERNAME -LogText "START part1.ps1"

Write-Log -ComputerName $COMPUTERNAME -LogText "TRACE Get passwords"
. $PASSWORDSFILE

# Update local admin password. This is needed for scheduled tasks later in this script

Write-Log -ComputerName $COMPUTERNAME -LogText "TRACE Change local admin password"
Set-LocalAdminPassword -UserID $LocalAdminID -Password $LocalAdminPwd

Write-Log -ComputerName $COMPUTERNAME -LogText "TRACE Create new scheduled task"
New-ScheduledTaskAtStartup -ScriptName "C:\Install\part2.ps1" -TaskName "Part2" -WorkingDirectory "C:\Install" -UserID $LocalAdminID -Password $LocalAdminPwd

Write-Log -ComputerName $COMPUTERNAME -LogText "TRACE Rename computer if needed"
Rename-ComputerIfNecessary -ComputerName $COMPUTERNAME

Write-Log -ComputerName $COMPUTERNAME -LogText "CHECK start part2.ps1 in 3 minutes"
Write-Log -ComputerName $COMPUTERNAME -LogText "END part1.ps1"

# Wait to be sure the data is sent to CloudWatch before the reboot starts is not needed in part1.ps1: the SSM agent will wait by default 60 seconds before rebooting

# No restart by this script: this script will prepare the rename and then stop. When this script stops without errors,
# cfn-init will stop and userdata will add the cfn-signal (with the current stack name) to the last partx.ps1 script and then reboot.
