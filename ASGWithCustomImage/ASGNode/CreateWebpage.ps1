# Create-Webpage.ps1
# ------------------
# Creates a new webpage every second

$LOGFILE = "C:\Install\install_log.txt"
$WEBPAGE = "/inetpub/wwwroot/index.html"

# Write-Log
# ---------
function Write-Log {
  param([String] $LogText)

  $CurrentTime = Get-Date -UFormat %H:%M:%S
  Write-Output "${env:COMPUTERNAME} ${CurrentTime} - ${LogText}" >> $LOGFILE
}

# Get-AWSCommand
# --------------
# AWS Commands can time out. When this is the case, the next call to AWS is in general fast enough. So: try until you have results.
function Get-AWSCommand {
  param([String] $Command)

  $Result = ""
  do {
    Write-Log -LogText "TRACE Start command: ${Command}"
    $Result = Invoke-Expression $Command
  } while ("${Result}" -EQ "")

  Write-Log -LogText "TRACE End command: ${Command}, result: ${Result}"
  return $Result
}

# Get-SSMParameter
# ----------------

function Get-SSMParameter {
  param([String] $Parameter)

  $ParameterRecord = Get-AWSCommand -Command "aws ssm get-parameter --name ${Parameter}"
  $Parameter=($ParameterRecord | ConvertFrom-Json).Parameter.Value

  return $Parameter
}

# Signal-ASG
# ----------
function Signal-ASG {

   . C:\Install\SignalASG.ps1
}

# Main Program
# ============

Write-Log -LogText "START CreateWebpage.ps1"
Write-Log -LogText "TRACE Signal ASG"

Signal-ASG

Write-Log -LogText "TRACE Start changing website"

while (1 -EQ 1) {

   $CurrentTime = get-date -Format "HH:mm:ss"
   Write-Output "<p> ${env:ComputerName} - ${CurrentTime} </p>" > $WEBPAGE

   Start-Sleep -Seconds 1

}