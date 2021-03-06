# Cluster-Online.ps1
# ------------------

$LOGFILE              = "C:\ClusterScripts\cluster_log.txt"
$NETWORKSETTINGS_FILE = "C:\ClusterScripts\NetworkSettings.ps1"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${env:COMPUTERNAME} ${CurrentTime} - $LogText" >> $LOGFILE
}

# Start-StoppedService
# --------------------
function Start-StoppedService {
  param([String] $ServiceName)

  Get-Service -name $ServiceName | Where-Object Status -EQ "Stopped" | Start-Service
}

# Start-StoppedApplicationPool
# ----------------------------
function Start-StoppedApplicationPool {

  Get-IISAppPool | Where-Object State -EQ "Stopped" | Start-WebAppPool
}

# Start-StoppedWebsites
# ---------------------
function Start-StoppedWebsites {

  Get-IISSite | Where-Object State -EQ "Stopped" | Start-IISSite
}

# Add-ClusterIPAddressesToThisNode
# --------------------------------
function Add-ClusterIPAddressesToThisNode {
  param([String] $Region,
        [String] $NetworkInterfaceIdPublic,
        [String] $NetworkInterfaceIdPrivate,
        [String] $IPAddressPublic,
        [String] $IPAddressPrivate,
        [String] $MacAddressPublic,
        [String] $MacAddressPrivate)

  $CountPublicIPAddresses=1
  while ($CountPublicIPAddresses -EQ 1) {
    Write-Log -Logtext "TRACE Add public cluster IP adresses to this node"
    aws ec2 assign-private-ip-addresses --allow-reassignment --region ${Region} --network-interface-id ${NetworkInterfaceIdPublic} --private-ip-addresses 10.0.0.50 10.0.0.51

    Start-Sleep -s 2

    Write-Log -Logtext "TRACE Check that addresses have been added on public interface"

    # Invoke-Webrequest will not return any output (not an error as well). Use cmd /C "curl" instead.
    $CountPublicIPAddresses=(cmd /C "curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MacAddressPublic/local-ipv4s" | Select-String -Pattern "10." | measure-object -Word).Words
    Write-Log -Logtext "TRACE $CountPublicIPAddresses IP addresses on public network interface"
  }  
}

# Main Program
# ============

Write-Log -LogText "START Cluster-Online.ps1"

Write-Log -LogText "TRACE Start stopped service W3SVC"
Start-StoppedService -ServiceName "W3SVC"

Write-Log -LogText "TRACE Start stopped application pools"
Start-StoppedApplicationPool

Write-Log -LogText "TRACE Start stopped websites"
Start-StoppedWebsites

Write-Log -LogText "TRACE Get networksettings"
. $NETWORKSETTINGS_FILE

Write-Log -LogText "TRACE Add IP Adresses of the cluster to this node"
Add-ClusterIPAddressesToThisNode -Region                   $Region `
                                 -NetworkInterfaceIdPublic $NetworkInterfaceIdPublic -NetworkInterfaceIdPrivate $NetworkInterfaceIdPrivate `
                                 -IPAddressPublic          $IPAddressPublic          -IPAddressPrivate          $ThisInstanceIPAddressPrivate `
                                 -MacAddressPublic         $MacAddressPublic         -MacAddressPrivate         $MacAddressPrivate

Write-Log -LogText "END Cluster-Online.ps1"
exit 0
