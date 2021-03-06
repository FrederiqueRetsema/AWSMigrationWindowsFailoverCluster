# Cluster-IsAlive.ps1
# -------------------

$LOGFILE = "C:\ClusterScripts\cluster_log.txt"
$WEBPAGE = "C:\inetpub\wwwroot\index.html"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${env:COMPUTERNAME} ${CurrentTime} - $LogText" >> $LOGFILE
}

# Test-UpdateWebpage
# ------------------
function Test-UpdateWebpage {
  param([String] $WebPage)

  $LastWriteTime   = (Get-ItemProperty $WebPage).LastWriteTime
  $TimeNow         = (GetDate)
  $TimeDiffSeconds = (New-TimeSpan -Start $LastWriteTime -End $TimeNow).Seconds

  if ($TimeDiffSeconds -GT 2) {
    write-log -LogText "ERROR create-webpage task isn't running anymore"
    write-log -LogText "END C:\ClusterScripts\Cluster-IsAlive.ps1 (ExitCode 1)"
    exit 1
  }
}

# Main Program
# ============

Write-Log -LogText "START Cluster-IsAlive.ps1"

write-log -LogText "TRACE Test update of webpage"
Test-UpdateWebpage -WebPage $WEBPAGE

write-log -LogText "TRACE Do regular tests in Cluster-LooksAlive as well"
. c:\ClusterScripts\Cluster-LooksAlive.ps1
$ExitCode = $LASTEXITCODE

write-log -LogText "END Cluster-IsAlive.ps1 (ExitCode Cluster-LooksAlive = $ExitCode)"
exit $ExitCode
