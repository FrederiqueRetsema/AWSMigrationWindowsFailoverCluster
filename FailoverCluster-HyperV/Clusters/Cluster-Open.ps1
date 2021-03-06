# Cluster-Open.ps1
# ----------------

$LOGFILE = "C:\ClusterScripts\cluster_log.txt"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${CurrentTime} - $LogText" >> $LOGFILE
}

# Main Program
# ============

Write-Log -LogText "START Cluster-Open.ps1"

Write-Log -LogText "END Cluster-Open.ps1"
exit 0
