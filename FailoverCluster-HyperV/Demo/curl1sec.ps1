# Curl1Sec.ps1
# ============
# Will do a curl to a specified address every second
#
# Example:
#
# . .\Curl1Sec -Address http://myiis 

param($Address)

do {
  $result=Invoke-Webrequest $Address
  write-host Output:
  write-host $result.Content
  Start-Sleep -Seconds 1
} while (1 -eq 1)
