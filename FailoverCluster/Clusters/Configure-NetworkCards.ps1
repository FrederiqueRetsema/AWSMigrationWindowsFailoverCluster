# Configure-NetworkCards
# ======================

$LOGFILE               = "C:\Install\install_log.txt"
$NETWORK_LOGFILE       = "C:\Install\network_info.txt"
$NETWORK_SETTINGS_FILE = "C:\ClusterScripts\NetworkSettings.ps1"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = get-date -UFormat %H:%M:%S
  Write-Output "${env:COMPUTERNAME} ${CurrentTime} - $LogText" >> $LOGFILE
}

# Get-AWSCommand
# --------------
# AWS Commands can time out. When this is the case, the next call to AWS is in general fast enough. So: try until you have results.
function Get-AWSCommand {
  param([String] $Command)

  $Result = ""
  do {
    Write-Log -LogText "TRACE Start command: ${Command}"
    $Result = Invoke-Expression $Command
  } while ("${Result}" -EQ "")

  Write-Log -LogText "TRACE End command: ${Command}, result: ${Result}"
  return $Result
}

# Get-SSMParameter
# ----------------

function Get-SSMParameter {
  param([String] $Parameter)

  $ParameterRecord = Get-AWSCommand -Command "aws ssm get-parameter --name ${Parameter}"
  $Parameter=($ParameterRecord | ConvertFrom-Json).Parameter.Value

  return $Parameter
}

# Disable-DHCP
# ------------
function Disable-DHCP {
  param([String] $IPAddressPublic,
        [String] $IPAddressPrivate)

  $LocalEthernetAdapterPublic = Get-NetIPAddress | Where-Object InterfaceAlias -Like "Ethernet*" | Where-Object IPAddress -EQ $IPAddressPublic
  $DefaultGateway = (Get-NetRoute -InterfaceIndex $LocalEthernetAdapterPublic.InterfaceIndex -DestinationPrefix 0.0.0.0/0).NextHop

  Set-NetIPInterface -InterfaceIndex $LocalEthernetAdapterPublic.InterfaceIndex  -Dhcp Disabled 
  New-NetIPAddress -InterfaceIndex $LocalEthernetAdapterPublic.InterfaceIndex  -IPAddress $IPAddressPublic -DefaultGateway $DefaultGateway -AddressFamily IPv4 -PrefixLength 24

  $LocalEthernetAdapterPrivate = Get-NetIPAddress | Where-Object InterfaceAlias -Like "Ethernet*" | Where-Object IPAddress -EQ $IPAddressPrivate
  Set-NetIPInterface -InterfaceIndex $LocalEthernetAdapterPrivate.InterfaceIndex -Dhcp Disabled 
  New-NetIPAddress -InterfaceIndex $LocalEthernetAdapterPrivate.InterfaceIndex -IPAddress $IPAddressPrivate -AddressFamily IPv4 -PrefixLength 24
}

# Set-DCAndAWSDNS
# ---------------
function Set-DCAndAWSDNS {
  param([String] $IPAddress,
        [String] $IPAddressDC,
        [String] $IPAddressAWSDNS)

  Write-Log -LogText "TRACE Use DC address and AWS DNS address for DNS for network card with IP address $IPAddress"
  $LocalEthernetAdapter = Get-NetIPAddress | Where-Object InterfaceAlias -Like "Ethernet*" | Where-Object IPAddress -EQ $IPAddress
  Set-DnsClientServerAddress -InterfaceIndex $LocalEthernetAdapter.InterfaceIndex -ServerAddresses $IPAddressDC,$IPAddressAWSDNS
}

# Save-DataForOtherScripts
# ------------------------
function Save-DataForOtherScripts {
  param([String] $IPAddressPublic,
        [String] $IPAddressPrivate,
        [String] $IPAddressDC,
        [String] $IPAddressAWSDNS)

  $ThisClusterNodeRecord = Get-AWSCommand -Command "aws ec2 describe-instances --filter 'Name=`"tag:NameInUppercase`",Values=`"$env:ComputerName`"'"
  $ThisClusterNode       = $ThisClusterNodeRecord | ConvertFrom-Json

  $NetworkInterfaceiDPublic = ($ThisClusterNode.Reservations.Instances.NetworkInterfaces | where-object PrivateIpAddress -EQ $IPAddressPublic).NetworkInterfaceId
  $MacAddressPublic         = ($ThisClusterNode.Reservations.Instances.NetworkInterfaces | where-object PrivateIpAddress -EQ $IPAddressPublic).MacAddress
  
  # $Region is also part of the network settings file, this is done by the clusternode yml file. 
  Write-Output "`$NetworkInterfaceIdPublic = `"${NetworkInterfaceIdPublic}`"" >> $NETWORK_SETTINGS_FILE
  Write-Output "`$IPAddressPublic = `"${IPAddressPublic}`"" >> $NETWORK_SETTINGS_FILE
  Write-Output "`$MacAddressPublic = `"${MacAddressPublic}`"" >> $NETWORK_SETTINGS_FILE 

  $NetworkInterfaceIdPrivate = ($ThisClusterNode.Reservations.Instances.NetworkInterfaces | where-object PrivateIpAddress -EQ $IPAddressPrivate).NetworkInterfaceId
  $MacAddressPrivate         = ($ThisClusterNode.Reservations.Instances.NetworkInterfaces | where-object PrivateIpAddress -EQ $IPAddressPrivate).MacAddress

  Write-Output "`$NetworkInterfaceIdPrivate = `"${NetworkInterfaceIdPrivate}`"" $NETWORK_SETTINGS_FILE 
  Write-Output "`$IPAddressPrivate  = `"${IPAddressPrivate}`"" >> $NETWORK_SETTINGS_FILE
  Write-Output "`$MacAddressPrivate = `"${MacAddressPrivate}`"" >> $NETWORK_SETTINGS_FILE 
}

function Write-NetworkInfoToNetworkLogFile {
  param([String] $NetworkLogFile)

  ipconfig /all >> $NetworkLogFile
  route print   >> $NetworkLogFile 
}

# Main Program
# ============

Write-Log -LogText "START Configure-NetworkCards.ps1"

Write-Log -LogText "TRACE Get passwords"
. c:\Install\uidspwds.ps1

Write-Log -LogText "TRACE Get IP Addresses from parameter store"
$NodeNameInLowercase = ($env:ComputerName).ToLower()

$IPAddressPublic  = Get-SSMParameter -Parameter "/${NodeNameInLowercase}/ipaddresspublic" 
$IPAddressPrivate = Get-SSMParameter -Parameter "/${NodeNameInLowercase}/ipaddressprivate" 
$IPAddressDC      = Get-SSMParameter -Parameter "/dc/ipaddress" 
$IPAddressAWSDNS  = Get-SSMParameter -Parameter "/_aws/dns/ipaddress" 

Write-Log -LogText "TRACE Disable DHCP"
Disable-DHCP -IPAddressPublic $IPAddressPublic -IPAddressPrivate $IPAddressPrivate

write-log -LogText "TRACE Set DNS address from both DC and AWS as DNS for all addresses"
Set-DCAndAWSDNS -IPAddress $IPAddressPublic  -IPAddressDC $IPAddressDC -IPAddressAWSDNS $IPAddressAWSDNS
Set-DCAndAWSDNS -IPAddress $IPAddressPrivate -IPAddressDC $IPAddressDC -IPAddressAWSDNS $IPAddressAWSDNS

Write-Log -LogText "TRACE Save data to switch faster"
Save-DataForOtherScripts -IPAddressPublic $IPAddressPublic -IPAddressPrivate $IPAddressPrivate 

Write-Log -LogText "TRACE Send result of these changes in IP Addresses and route info to network log file "
Write-NetworkInfoToNetworkLogFile -NetworkLogFile $NETWORK_LOGFILE

Write-Log -LogText "END Configure-NetworkCards.ps1"
