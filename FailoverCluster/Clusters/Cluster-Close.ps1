# Cluster-Close.ps1
# -----------------

$LOGFILE = "C:\ClusterScripts\cluster_log.txt"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${env:COMPUTERNAME} ${CurrentTime} - $LogText" >> $LOGFILE
}

# Main Program
# ============

Write-Log -LogText "START Cluster-Close.ps1"

Write-Log -LogText "END Cluster-Close.ps1"
exit 0
