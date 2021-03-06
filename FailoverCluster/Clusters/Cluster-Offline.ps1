# Cluster-Offline.ps1
# -------------------

$LOGFILE              = "C:\ClusterScripts\cluster_log.txt"
$NETWORKSETTINGS_FILE = "C:\ClusterScripts\NetworkSettings.ps1"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${env:COMPUTERNAME} ${CurrentTime} - $LogText" >> $LOGFILE
}

# Stop-StartedWebsites
# --------------------
function Stop-StartedWebsites {

  Get-IISite | Where-Object State -EQ "Started" | Stop-IISSite -Confirm:$false
}

# Stop-StartedApplicationPools
# ----------------------------
function Stop-StartedApplicationPools {

  Get-IISAppPool | Where-object State -EQ "Started" | Stop-WebAppPool
}

# Stop-RunningService 
# -------------------
function Stop-RunningService {
  param([String] $ServiceName)

  Get-Service $ServiceName | Where-Object Status -EQ "Running" | Stop-Service
}

# Remove-ClusterIPAddressesFromThisNode
# -------------------------------------
function Remove-ClusterIPAddressesFromThisNode {
param([String] $Region,
      [String] $NetworkInterfaceIdPublic,
      [String] $NetworkInterfaceIdPrivate,
      [String] $IPAddressPublic,
      [String] $IPAddressPrivate,
      [String] $MacAddressPublic,
      [String] $MacAddressPrivate)

  $CountPublicIPAddresses=3
  while ($CountPublicIPAddresses -NE 1) {
    Write-Log -Logtext "TRACE Remove public cluster IP adresses from this node"
    aws ec2 unassign-private-ip-addresses --region ${Region} --network-interface-id ${NetworkInterfaceIdPublic} --private-ip-addresses 10.0.0.50 10.0.0.51

    Start-Sleep -s 2

    Write-Log -Logtext "TRACE Check if addresses have been removed from public network interface"

    # Invoke-Webrequest will not return any output (not an error as well). Use cmd /C "curl" instead.
    $CountPublicIPAddresses=(cmd /C "curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MacAddressPublic/local-ipv4s" | Select-String -Pattern "10." | measure-object -Word).Words
    Write-Log -Logtext "TRACE $CountPublicIPAddresses IP addresses on public network interface"
  }

}

# Main Program
# ------------

Write-Log -LogText "START Cluster-Offline.ps1"

Write-Log -LogText "TRACE Stop started websites"
Stop-StartedWebsites

Write-Log -LogText "TRACE Stop started application pools"
Stop-StartedApplicationPools

Write-Log -LogText "TRACE Stop running W3SVC service"
Stop-RunningService -ServiceName "W3SVC"

write-log($logtext="TRACE Get networksettings")
. $NETWORKSETTINGS_FILE = "C:\ClusterScripts\NetworkSettings.ps1"

write-log($logtext="TRACE Remove cluster IP adresses from this node")
Remove-ClusterIPAddressesFromThisNode -Region                   $Region `
                                      -NetworkInterfaceIdPublic $NetworkInterfaceIdPublic    -NetworkInterfaceIdPrivate $NetworkInterfaceIdPrivate `
                                      -IPAddressPublic          $ThisInstanceIPAddressPublic -IPAddressPrivate          $IPAddressPrivate `
                                      -MacAddressPublic         $MacAddressPublic            -MacAddressPrivate         $MacAddressPrivate

write-log($logtext="END Cluster-Offline.ps1")
exit 0
