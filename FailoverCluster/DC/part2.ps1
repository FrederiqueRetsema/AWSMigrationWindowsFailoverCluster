# Part 2 of the install
# ---------------------

$LOGFILE = "C:\Install\install_log.txt"

function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${env:COMPUTERNAME} ${CurrentTime} - ${LogText}" >> $LOGFILE
}

# Remove-ScheduledTask
# --------------------
function Remove-ScheduledTask {
  param([String] $TaskName)

  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Get-LocalIPAddress 
# ------------------
function Get-LocalIPAddress {

  $LocalIPAddress = Get-NetIPAddress | Where-Object InterfaceAlias -Like "Ethernet*" | Where-Object IPAddress -Like "10.*" | Select-Object IPAddress
  return $LocalIPAddress
}

# Set-DNSSearchList
# -----------------
function Set-DNSSearchList {
  param([String] $SearchList)

  Set-DnsClientGlobalSetting -SuffixSearchList $SearchList
}

# Install-WindowsFeatureDC
# ------------------------
function Install-WindowsFeatureDC {

  Install-Windowsfeature -IncludeManagementTools AD-Domain-Services
}

# Install-ADDSForestForCluster
# ----------------------------
function Install-ADDSForestForCluster {
  param([String] $DomainAdminPwd)

  $SecureDomainAdminPwd = ConvertTo-SecureString $DomainAdminPwd -AsPlainText -Force
  Install-ADDSForest -DomainName ONP-1234.ORG -SafeModeAdministratorPassword $SecureDomainAdminPwd -Force
}

Write-Log -LogText "START part2.ps1"

Write-Log -LogText "TRACE Get passwords"
. C:\Install\uidspwds.ps1

Write-Log -LogText "TRACE Remove current startup job for install"
Remove-ScheduledTask -TaskName "Part2"

Write-Log -LogText "TRACE Get local ip address"
$LocalIPAddress = Get-LocalIPAddress

Write-Log -LogText "TRACE Change DNS search list"
Set-DNSSearchList -SearchList "onp-1234.org"

Write-Log -LogText "TRACE Install Windowsfeature"
Install-WindowsFeatureDC

Write-Log -LogText "TRACE Install ADDS Forest"
Install-ADDSForestForCluster -DomainAdminPwd "${DomainAdminPwd}"

Write-Log -LogText "TRACE Ready, send signal"
Write-Log -LogText "END part2.ps1"
