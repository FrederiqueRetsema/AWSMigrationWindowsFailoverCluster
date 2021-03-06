# Cluster-LooksAlive.ps1
# ----------------------

$LOGFILE = "C:\ClusterScripts\cluster_log.txt"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${CurrentTime} - $LogText" >> $LOGFILE
}

# Test-ServiceRunning
# -------------------
function Test-ServiceRunning {
  param([String] $ServiceName)

  $NumberOfRunningW3SVCServices=(get-service $ServiceName | Where-Object Status -EQ "Running" | measure-object).Count
  if ($NumberOfRunningW3SVCServices -EQ 0) {
    Write-Log -LogText "ERROR Service ${ServiceName} not running"
    Write-Log -LogText "END Cluster-LooksAlive.ps1 (ExitCode 1)"
    exit 1 
  }

}

# Test-ApplicationPoolRunning
# ---------------------------
function Test-ApplicationPoolRunning {

  $NumberOfRunningApplicationPools=(Get-IISAppPool | Where-object State -EQ "Started" | measure-object).Count
  if ($NumberOfRunningApplicationPools -EQ 0) {

    Write-Log -LogText "ERROR Application Pool not running"
    Write-Log -LogText "END Cluster-LooksAlive.ps1 (ExitCode 1)"

    exit 1
  }

}

# Test-WebsiteRunning
# -------------------
function Test-WebsiteRunning {

  $NumberOfRunningWebsites=(get-iissite | Where-Object State -EQ "Started" | measure-object).Count
  if ($NumberOfRunningWebsites -EQ 0) {

    Write-Log -LogText "ERROR Website not running"
    Write-Log -LogText "END Cluster-LooksAlive.ps1 (ExitCode 1)"

    exit 1
  }

}

# Main Program
# ============

Write-Log -LogText "START Cluster-LooksAlive.ps1"

Write-Log -LogText "TRACE Test Service running"
Test-ServiceRunning -ServiceName "W3SVC"
	
Write-Log -LogText "TRACE Test Application Pool running"
Test-ApplicationPoolRunning

Write-Log -LogText "TRACE Test Website running"
Test-WebsiteRunning

Write-Log -LogText "END Cluster-LooksAlive.ps1"
exit 0
