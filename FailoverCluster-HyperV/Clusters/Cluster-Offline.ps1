# Cluster-Offline.ps1
# -------------------

$LOGFILE = "C:\ClusterScripts\cluster_log.txt"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${CurrentTime} - $LogText" >> $LOGFILE
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

# Main Program
# ------------

Write-Log -LogText "START Cluster-Offline.ps1"

Write-Log -LogText "TRACE Stop running websites"
Stop-StartedWebsites

Write-Log -LogText "TRACE Stop running application pools"
Stop-StartedApplicationPools

Write-Log -LogText "TRACE Stop running W3SVC service"
Stop-StartedService -ServiceName "W3SVC"

write-log($logtext="END Cluster-Offline.ps1")
exit 0