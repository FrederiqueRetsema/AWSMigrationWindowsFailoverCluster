# ASGNode - part 1
# ================

$LOGFILE       = "C:\Install\install_log.txt"
$PASSWORDSFILE = "C:\Install\uidspwds.ps1"

# Invoke-Webrequest will not return any output (not an error as well). Use cmd /C "curl" instead.
# Use the (first part of the) instance-id of the current computer
$COMPUTERNAME  = (cmd /C "curl http://169.254.169.254/latest/meta-data/instance-id")

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
  Register-ScheduledTask -TaskName "${TaskName}" -Action $Action -Trigger $Trigger -User "${UserID}" -Password "${Password}"
}

# Set-LocalAdminPassword 
# -------------------------
function Set-LocalAdminPassword {
  param([String] $UserID,
        [String] $Password)

  $SecureLocalAdminPwd = ConvertTo-SecureString -String $Password -AsPlainText -Force
  Set-LocalUser -Name $UserID -Password $SecureLocalAdminPwd  
}

# Install-WindowsFeaturesWebServer
# ---------------------------------
function Install-WindowsFeaturesWebServer {
  
  Install-Windowsfeature -IncludeManagementTools Web-Server
}

# Rename-ComputerIfNecessary
# --------------------------
function Rename-ComputerIfNecessary {
  param([String] $ComputerName)

  if ("$env:computername" -ne "$ComputerName") {
  	Rename-Computer -NewName "$ComputerName" -Confirm:$false -Force
  }
}

# Main Program
# ============

Write-Log -ComputerName $COMPUTERNAME -LogText "START part1.ps1"
Write-Log -ComputerName $COMPUTERNAME -LogText "TRACE Get passwords"
. $PASSWORDSFILE

Write-Log -ComputerName $COMPUTERNAME -LogText "TRACE Set local administrator password"
Set-LocalAdminPassword -UserID $LocalAdminID -Password $LocalAdminPwd

Write-Log -ComputerName $COMPUTERNAME -LogText "TRACE Rename computer if necessary"
Rename-ComputerIfNecessary -ComputerName $COMPUTERNAME

Write-Log -ComputerName $COMPUTERNAME -LogText "TRACE Install Windows feature"
Install-WindowsFeaturesWebServer

Write-Log -ComputerName $COMPUTERNAME -LogText "TRACE Create new scheduled task for creating a new webpage every second (will run forever)"
New-ScheduledTaskAtStartup -ScriptName "C:\Install\CreateWebpage.ps1" -TaskName "CreateWebpage" -WorkingDirectory "C:\Install" -UserID $LocalAdminID -Password $LocalAdminPwd

Write-Log -ComputerName $COMPUTERNAME -LogText "TRACE Create new scheduled task for next shell script"
New-ScheduledTaskAtStartup -ScriptName "C:\Install\part2.ps1" -TaskName "Part2" -WorkingDirectory "C:\Install" -UserID $LocalAdminID -Password $LocalAdminPwd

Write-Log -ComputerName $COMPUTERNAME -LogText "TRACE enforce reboot"
Write-Log -ComputerName $COMPUTERNAME -LogText "CHECK start part2.ps1 in 3 minutes"
Write-Log -ComputerName $COMPUTERNAME -LogText "CHECK start CreateWebpage.ps1 in 3 minutes"
Write-Log -ComputerName $COMPUTERNAME -LogText "END part1.ps1"

# Wait to be sure the data is sent to CloudWatch before the reboot starts is not needed in part1.ps1: the SSM agent will wait by default 60 seconds before rebooting

# No restart by this script: this script will prepare the rename and then stop. When this script stops without errors,
# cfn-init will stop and userdata will add the cfn-signal (with the current stack name) to the last partx.ps1 script and then reboot.

