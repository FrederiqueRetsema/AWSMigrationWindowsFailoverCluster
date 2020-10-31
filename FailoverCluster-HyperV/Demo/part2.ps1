# Part 2 of the Demo VM installation
# ==================================

$LOGFILE          = "C:\Install\install_log.txt"
$CURLPATH         = "C:\"

$LOCALIPADDRESS   = "10.0.0.24"
$LOCALDCIPADDRESS = "10.0.0.5"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${CurrentTime} - $LogText" >> $LOGFILE
}

# Remove-ScheduledTask
# --------------------
function Remove-ScheduledTask {
  param([String] $TaskName)

  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Get-LocalEthernetAdapter
# ------------------------
function Get-LocalEthernetAdapter {

  $LocalEthernetAdapter = Get-NetIPAddress | Where-Object AddressFamily -EQ "IPv4" | Where-Object IPv4Address -NE "127.0.0.1"
  return $LocalEthernetAdapter
}

# New-IPAddress
# -------------
# Start-Sleep is needed because the configuring of network cards takes some time (f.e. routing tables). 
# When the Start-Sleep is not there, joining the domain will not work.

function New-IPAddress {
  param([String] $IPAddress,
        [Int]    $InterfaceIndex)

  New-NetIPAddress $IPAddress -InterfaceIndex $InterfaceIndex -PrefixLength 24

  Start-Sleep -Seconds 8
}

# Set-DNSToDC
# -----------
function Set-DNSToDC {
  param([String] $IPAddress)

  Set-DnsClientServerAddress -InterfaceIndex $LocalEthernetAdapter.InterfaceIndex -ServerAddresses $IPAddress
}

# Update-DNS
# ----------
function Update-DNS {
  param([String] $DNSIPAddress)
  
  $LocalEthernetAdapter = Get-NetIPAddress | Where-Object AddressFamily -EQ "IPv4" | Where-Object IPv4Address -NE "127.0.0.1"
  New-NetIPAddress "10.0.0.24" -InterfaceIndex $LocalEthernetAdapter.InterfaceIndex -PrefixLength 24
  Set-DnsClientServerAddress -InterfaceIndex $LocalEthernetAdapter.InterfaceIndex -ServerAddresses $DNSIPAddress
}

# Move-CurlScriptToCurlPath
# -------------------------
function Move-CurlScriptToCurlPath {
  param([String] $CurlPath)
  
  Move-Item C:\Install\curl1sec.ps1 $CurlPath 
}

# Join-Domain
# -----------
function Join-Domain {
  param([String] $Password)

  $SecureDomainAdminPwd = ConvertTo-SecureString -String $Password -AsPlainText -Force
  $MachineCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "ONP-1234\Administrator",$SecureDomainAdminPwd
  Add-Computer -domainname ONP-1234.ORG -Credential $MachineCred -restart -force
}

# Main Program
# ============

Write-Log -LogText "START C:\Install\part2.ps1"

Write-Log -LogText "TRACE Get passwords"
. C:\Install\uidspwds.ps1

Write-Log -LogText "TRACE Remove current startup job for install"
Remove-ScheduledTask -TaskName "Part2"

Write-Log -LogText "TRACE Get LocalEthernetAdapter"
$LocalEthernetAdapter = Get-LocalEthernetAdapter

Write-Log -LogText "TRACE New IP Address"
New-IPAddress -IPAddress $LOCALIPADDRESS -InterfaceIndex $LocalEthernetAdapter.InterfaceIndex

Write-Log -LogText "TRACE Set DNS to DC"
Set-DNSToDc -IPAddress $LOCALDCIPADDRESS 

Write-Log -LogText "TRACE Change DNS search list"
Set-DnsClientGlobalSetting -SuffixSearchList "onp-1234.org"

Write-Log -LogText "TRACE Move curl1sec.ps1 to ${CURLPATH}"
Move-CurlScriptToCurlPath -CurlPath $CURLPATH

Write-Log -LogText "TRACE Domain join (enforces reboot)"
Join-Domain -Password $DomainAdminPwd

Write-Log -LogText "TRACE Enforce reboot"
Write-Log -LogText "END C:\Install\part2.ps1"
Restart-Computer -Force
