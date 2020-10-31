# Cluster install script - part 2
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

# Remove-ScheduledTask
# --------------------
function Remove-ScheduledTask {
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
  Register-ScheduledTask -TaskName "${TaskName}" -Action $Action -Trigger $Trigger -User "${UserID}" -Password "${Password}"
}

# Get-AWSCommand
# --------------
# AWS Commands can time out. When this is the case, the next call to AWS is in general fast enough. So: try until you have results.
function Get-AWSCommand {
  param([String] $Command)

  $Result = ""
  do {
    $Result = Invoke-Expression $Command
  } while ("${Result}" -EQ "")

  return $Result
}

# Add-DNS 
# -------
function Add-DNS {

  $LocalEthernetAdapter = Get-NetIPAddress | Where-Object InterfaceAlias -Like "Ethernet*" | Where-Object IPAddress -Like "10.*"
  $ResultAWSCommand = Get-AWSCommand -Command "aws ssm get-parameter --name /dc/ipaddress"
  $LocalDCIPAddress = ($ResultAWSCommand | ConvertFrom-Json).Parameter.Value

  Set-DnsClientServerAddress -InterfaceIndex $LocalEthernetAdapter.InterfaceIndex -ServerAddresses $LocalDCIPAddress
}

# Set-DNSSearchList 
# -----------------
function Set-DNSSearchList {
  param([String] $SuffixSearchList)

  Set-DnsClientGlobalSetting -SuffixSearchList $SuffixSearchList
}

# Join-Domain
# -----------
function Join-Domain {
  param([String] $UserID,
        [String] $Password)

  $SecureDomainAdminPwd = ConvertTo-SecureString -String $Password -AsPlainText -Force
  $MachineCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserID,$SecureDomainAdminPwd
  Add-Computer -DomainName ONP-1234.ORG -Credential $MachineCred -Restart -Force
}

# Main Program
# ============

Write-Log -LogText "START part2.ps1"

Write-Log -LogText "TRACE Get passwords"
. $PASSWORDSFILE

Write-Log -LogText "TRACE Remove current job"
Remove-ScheduledTask -TaskName "Part2"

Write-Log -LogText "TRACE Create new scheduled task"
New-ScheduledTaskAtStartup -ScriptName "C:\Install\part3.ps1" -TaskName "Part3" -WorkingDirectory "C:\Install" -UserID $LocalAdminID -Password $LocalAdminPwd

Write-Log -LogText "TRACE Add DC to DNS on network card with public IP address"
# Mind, that on this moment in time, the network card with the private IP address is not part of this VM yet, that network card will be added after part1 - partx are executed
# We need to have the DC added to this network card because otherwise the domain join will not be possible
Add-DNS

Write-Log -LogText "TRACE Set DNS search list"
Set-DNSSearchList -SuffixSearchList "onp-1234.org"

Write-Log -LogText "TRACE Domain join (enforces reboot)"
Join-Domain -UserID $DomainAdminID -Password $DomainAdminPwd

Write-Log -LogText "TRACE Enforce reboot"
Write-Log -LogText "CHECK start part3.ps1 in 2 minutes"
Write-Log -LogText "END part2.ps1"

# Wait for 10 seconds to be sure the data is sent to CloudWatch before the reboot starts
Start-Sleep -Seconds 10

Restart-Computer -Force
