# Create-Webpage.ps1
# ------------------
# Creates a new webpage every second

$LOGFILE = "C:\Install\install_log.txt"
$WEBPAGE = "/inetpub/wwwroot/index.html"

function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${env:COMPUTERNAME} ${CurrentTime} - ${LogText}" >> $LOGFILE
}

# Main Program
# ============

Write-Log -LogText "START CreateWebpage.ps1"

while (1 -EQ 1) {

   $CurrentTime = get-date -Format "HH:mm:ss"
   Write-Output "<p> ${env:ComputerName} - ${CurrentTime} </p>" > $WEBPAGE

   Start-Sleep -Seconds 1

}