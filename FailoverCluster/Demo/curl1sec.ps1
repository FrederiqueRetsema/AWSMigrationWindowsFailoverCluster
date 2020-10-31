# Curl1Sec
# ========

param($Address)

do {
  $result=Invoke-Webrequest $Address
  write-host Output:
  write-host $result.Content
  Start-Sleep -Seconds 1
} while (1 -eq 1)
