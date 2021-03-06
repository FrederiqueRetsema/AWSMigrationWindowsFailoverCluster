# Cluster-Online.ps1
# ------------------

$LOGFILE = "C:\ClusterScripts\cluster_log.txt"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${CurrentTime} - $LogText" >> $LOGFILE
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

# Main Program
# ============

Write-Log -LogText "START Cluster-Online.ps1"

Write-Log -LogText "TRACE Start stopped service W3SVC"
Start-StoppedService -ServiceName "W3SVC"

Write-Log -LogText "TRACE Start stopped application pools"
Start-StoppedApplicationPool

Write-Log -LogText "TRACE Start stopped websites"
Start-StoppedWebsites

Write-Log -LogText "END Cluster-Online.ps1"
exit 0