# Curl1Sec
# ========

param($Address)

do {
  $Result=Invoke-Webrequest $Address

  write-host Output:
  write-host $Result.Content

  Start-Sleep -Seconds 1

} while (1 -eq 1)
