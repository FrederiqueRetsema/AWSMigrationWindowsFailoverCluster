# Cluster install script - part 2
# ===============================

$LOGFILE          = "C:\Install\install_log.txt"
$LOCALDCIPADDRESS = "10.0.0.5"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${CurrentTime} - $LogText" >> $LOGFILE
}

# Get-PublicIPAddress
# -------------------
function Get-PublicIPAddress {
  param([String] $ComputerName)

  $PublicIPAddress = ""
  if ("${ComputerName}" -EQ "CLUSTERNODE1") {
    $PublicIPAddress = "10.0.0.11"
  } 
  
  if ("${ComputerName}" -EQ "CLUSTERNODE2") {
    $PublicIPAddress = "10.0.0.12"
  } 
  
  if ("${ComputerName}" -EQ "CLUSTERNODE3") {
    $PublicIPAddress = "10.0.0.13"
  }
  
  if ("${PublicIPAddress}" -EQ "") {
    Write-Log -LogText "ERROR: incorrect computername, cannot determine public IP address"
    Write-Error "ERROR: Incorrect computername, cannot determine public IP address"
    exit 1
  }
  
  return $PublicIPAddress
}

# Get-PrivateIPAddress
# --------------------
function Get-PrivateIPAddress {
  param([String] $ComputerName)

  if ("${ComputerName}" -EQ "CLUSTERNODE1") {
    $PrivateIPAddress = "10.0.1.11"
  } 

  if ("${ComputerName}" -EQ "CLUSTERNODE2") {
    $PrivateIPAddress = "10.0.1.12"
  } 

  if ("${ComputerName}" -EQ "CLUSTERNODE3") {
    $PrivateIPAddress = "10.0.1.13"
  }

  if ("${PrivateIPAddress}" -EQ "") {
    Write-Log -LogText "ERROR incorrect computername, cannot determine private IP address"
    Write-Error "Incorrect computername, cannot determine private IP address"
    exit 1
  }
  
  return $PrivateIPAddress
}

# Remove-ScheduledTask
# --------------------
function Remove-ScheduledTask {
  param([String] $TaskName)

  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false

}

# New-IPAdresses
# --------------
# Start-Sleep is needed because when you change IP Addresses, other configuration is changed in the background as well.
# When the sleep is not there, then the changes will go too fast and the network configuration is messed up.

function New-IPAdresses {
  param([String] $EthernetAddress,
        [String] $Ethernet2Address)

  Get-NetIPAddress -InterfaceAlias "Ethernet"   -AddressFamily IPv4 | New-NetIPAddress "${EthernetAddress}" -PrefixLength 24
  Get-NetIPAddress -InterfaceAlias "Ethernet 2" -AddressFamily IPv4 | New-NetIPAddress "${Ethernet2Address}" -PrefixLength 24

  Start-Sleep -Seconds 8
}

# Remove-IPAddresses
# ------------------
# Start-Sleep is needed because when you change IP Addresses, other configuration is changed in the background as well.
# When the sleep is not there, then the changes will go too fast and the network configuration is messed up.

function Remove-IPAddresses {
  param([String] $PublicIPAddress,
        [String] $PrivateIPAddress)
  
  Get-NetIPAddress -InterfaceAlias "Ethernet"   -AddressFamily IPv4 | Remove-NetIPAddress ${PublicIPAddress} -Confirm:$False
  Get-NetIPAddress -InterfaceAlias "Ethernet 2" -AddressFamily IPv4 | Remove-NetIPAddress ${PrivateIPAddress} -Confirm:$False

  Start-Sleep -Seconds 8
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

# Update-InterfaceIfNecessary
# ---------------------------
# Sometimes, the first network adapter in Hyper-V corresponds to Ethernet, the second to Ethernet 2. Sometimes, however, it is the other way around.
# Check if the correct IP address matches the correct VLAN by pinging the DC (10.0.0.5), and when packets are returned (in x ms) nothing needs to be done.
# When no packets are returned, then swap the IP adresses and try again. 
#
# When this also isn't successful, we'd better stop with an error because it is impossible to reach the DC to join to the network. 

function Update-InterfaceIfNecessary {
  param([String] $PublicIPAddress,
        [String] $PrivateIPAddress)

  if ((ping 10.0.0.5 | Select-String "ms" | Measure-Object).Count -EQ 0) {
    Write-Log -LogText "TRACE 10.0.0.5 not reachable, update interface"

    Remove-IPAddresses -PublicIPAddress $PublicIPAddress -PrivateIPAddress $PrivateIPAddress
    New-IPAdresses -EthernetAddress $PrivateIPAddress -Ethernet2Address $PublicIPAddress
  
    Write-Log -LogText "TRACE Check again"
    if ((ping 10.0.0.5 | Select-String "ms" | measure-object).Count -EQ 0) {

      Write-Log -LogText "ERROR No ping to 10.0.0.5 (DC) possible, stop"
      Write-Error "ERROR No ping to 10.0.0.5 (DC) possible, stop"
      exit 1

    }
    write-log -LogText "TRACE update successful"
  }
  
}

# Add-DNS 
# -------
function Add-DNS {
  param([String] $PublicIPAddress,
        [String] $DNSIPAddress)

  Get-NetIPAddress -IPAddress $PublicIPAddress | Set-DnsClientServerAddress -ServerAddresses $DNSIPAddress

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
  param([String] $Password)

  $SecureDomainAdminPwd = ConvertTo-SecureString -String $Password -AsPlainText -Force
  $MachineCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "ONP-1234\Administrator",$SecureDomainAdminPwd
  Add-Computer -DomainName ONP-1234.ORG -Credential $MachineCred -Restart -Force
}

# Main Program
# ============

Write-Log -LogText "START part2.ps1"
Write-Log -LogText "TRACE Set clustername dependent constants"

$PUBLICIPADDRESS  = Get-PublicIPAddress -ComputerName "${env:COMPUTERNAME}"
$PRIVATEIPADDRESS = Get-PrivateIPAddress -ComputerName "${env:COMPUTERNAME}"

Write-Log -LogText "TRACE Get passwords"
. c:\Install\uidspwds.ps1

Write-Log -LogText "TRACE Remove current job"
Remove-ScheduledTask -TaskName "Part2"

Write-Log -LogText "TRACE Create new scheduled task"
New-ScheduledTaskAtStartup -ScriptName "C:\Install\part3.ps1" -TaskName "Part3" -WorkingDirectory "C:\Install" -UserID "Administrator" -Password $LocalAdminPwd

Write-Log -LogText "TRACE New IP addresses"
New-IPAdresses -EthernetAddress $PUBLICIPADDRESS -Ethernet2Address $PRIVATEIPADDRESS

# Sometimes, the first network adapter in Hyper-V corresponds to Ethernet, the second to Ethernet 2. Sometimes, however, it is the other way around.
# Update the IP adresses if the assumption that the Ethernet corresponds with the public VLan and that Ethernet 2 corresponds with the private VLan is incorrect  
Write-Log -LogText "TRACE Switch interface if necessary"
Update-InterfaceIfNecessary -PublicIPAddress $PUBLICIPADDRESS -PrivateIPAddress $PRIVATEIPADDRESS

Write-Log -LogText "TRACE Add DC to DNS on network card with public IP address"
Add-DNS -PublicIPAddress $PUBLICIPADDRESS -DNSIPAddress $LOCALDCIPADDRESS

Write-Log -LogText "TRACE Set DNS search list"
Set-DNSSearchList -SuffixSearchList "onp-1234.org"

write-log -LogText "TRACE Domain join (enforces reboot)"
Join-Domain -password $DomainAdminPwd

Write-Log -LogText "TRACE Enforce reboot"
Write-Log -LogText "END part2.ps1"
Restart-Computer -Force
