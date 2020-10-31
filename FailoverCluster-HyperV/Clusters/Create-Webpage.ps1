# Create-Webpage.ps1
# ------------------
# Creates a new webpage every second

$WEBPAGE = "/inetpub/wwwroot/index.html"

while (1 -EQ 1) {

   $CurrentTime = get-date -Format "HH:mm:ss"
   Write-Output "<p> ${env:ComputerName} - ${CurrentTime} </p>" > $WEBPAGE

   Start-Sleep -Seconds 1

}