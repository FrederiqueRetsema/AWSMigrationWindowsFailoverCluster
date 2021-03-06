# Configure-Cluster
# =================

$LOGFILE             = "C:\Install\install_log.txt"
$NETWORKSETTINGSFILE = "C:\ClusterScripts\NetworkSettings.ps1" 

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${env:COMPUTERNAME} ${CurrentTime} - $LogText" >> $LOGFILE
}

# Test-MyCluster
# --------------
function Test-MyCluster {

  Test-Cluster -Node ClusterNode1.onp-1234.org, `
                     ClusterNode2.onp-1234.org, `
                     ClusterNode3.onp-1234.org
}

# New-MyCluster
# -------------
function New-MyCluster {

  New-Cluster -Name MyCluster `
              -Node ClusterNode1.onp-1234.org, `
                    ClusterNode2.onp-1234.org, `
                    ClusterNode3.onp-1234.org `
              -StaticAddress 10.0.0.50 `
              -IgnoreNetwork 10.0.1.0/24 `
              -NoStorage `
              -Force
}

# Add-MyClusterIIS
# ----------------
function Add-MyClusterIIS {

  Add-ClusterGenericScriptRole -Name MyClusterIIS `
                               -ScriptFilePath C:\ClusterScripts\myclusteriis-entrypoints.vbs `
                               -StaticAddress 10.0.0.51
}

# Main Program
# ============

Write-Log -LogText "START Configure-Cluster.ps1"
Write-Log -LogText "TRACE Get network settings"
. $NETWORKSETTINGSFILE

Write-Log -LogText "TRACE Test MyCluster"
Test-MyCluster

Write-Log -LogText "TRACE New MyCluster"
New-MyCluster

Write-Log -LogText "TRACE Add MyClusterIIS"
Add-MyClusterIIS

Write-Log -LogText "END Configure-Cluster.ps1"
