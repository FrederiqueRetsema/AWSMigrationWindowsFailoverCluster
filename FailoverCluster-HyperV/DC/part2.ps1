# Part 2 of the DC installation
# =============================

$LOGFILE = "C:\Install\install_log.txt"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S 
  Write-Output "${CurrentTime} - $LogText" >> $LOGFILE
}

# Remove-CurrentStartupJob
# ------------------------
function Remove-CurrentStartupJob {
  param([String] $TaskName)

  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false 
}

# New-IPAddress
# -------------
# Start-Sleep is needed because the configuring of network cards (including routing tables etc.) takes some time. 

function New-IPAddress {
  param([String] $NewIPAddress)

  $NetIPAddress=Get-NetIPAddress |where-object AddressFamily -EQ "IPv4" |where-object IPv4Address -NE "127.0.0.1" 
  New-NetIPAddress $NewIPAddress -InterfaceIndex $NetIPAddress.InterfaceIndex -PrefixLength 24 

  Start-Sleep -Seconds 8
}

# Set-DNSSearchList
# -----------------
function Set-DNSSearchList {
  param([String] $NewSearchList)

  Set-DnsClientGlobalSetting -SuffixSearchList $NewSearchList 
}

# Enable-ICMP4Requests
# --------------------
function Enable-ICMP4Requests {

  Enable-NetFirewallRule -Name "vm-monitoring-icmpv4" 

}

# Install-WindowsFeaturesForDC
# ----------------------------
function Install-WindowsFeaturesForDC {

  Install-Windowsfeature -IncludeManagementTools AD-Domain-Services 

}

# Configure-ADDSForest
# --------------------
function Configure-ADDSForest {
  param([String] $Password)

  $SecureDomainAdminPwd = ConvertTo-SecureString $Password -AsPlainText -Force 
  Install-ADDSForest -DomainName ONP-1234.ORG -SafeModeAdministratorPassword $SecureDomainAdminPwd -Force 

}

# Main program
# ============

Write-Log -LogText "START part2.ps1"

Write-Log -LogText "TRACE Get passwords"
. C:\Install\uidspwds.ps1

Write-Log -LogText "TRACE Remove current startup job for install"
Remove-CurrentStartupJob -TaskName "Part2"

Write-Log -LogText "TRACE New IP address is 10.0.0.5"
New-IPAddress -NewIPAddress "10.0.0.5"

Write-Log -LogText "TRACE Set DNS search list"
Set-DNSSearchList -NewSearchList "onp-1234.org" 

Write-Log -LogText "TRACE Enable ICMP-4 requests to make it possible to check if the correct IP address is connected to the correct netadapter in ClusterNodes"
Enable-ICMP4Requests

Write-Log -LogText "TRACE Install Windowsfeatures for DC"
Install-WindowsFeaturesForDC

write-log -LogText "TRACE Configure ADDS Forest"
Configure-ADDSForest -Password $DomainAdminPwd

write-log -LogText "END part2.ps1"
