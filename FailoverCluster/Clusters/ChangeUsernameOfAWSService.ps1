# 
# Change service user name and password 
# www.sivarajan.com 
#
# Based on: https://gallery.technet.microsoft.com/scriptcenter/79644be9-b5e1-4d9e-9cb5-eab1ad866eaf
# And: https://stackoverflow.com/questions/313831/using-powershell-how-do-i-grant-log-on-as-service-to-an-account

. C:\Install\uidspwds

# Add user to Log on as a Service 
# -------------------------------

#The SID you want to add
#$AccountSid = 'S-1-5-21-1234567890-1234567890-123456789-500'

$Account     = Get-WmiObject Win32_useraccount -filter "name='Administrator' and Domain='ONP-1234'"
$AccountSid  = $Account.SID

$ExportFile  = 'C:\Install\Temp\CurrentConfig.inf'
$SecDb       = 'C:\Install\Temp\Secedt.sdb'
$ImportFile  = 'C:\Install\Temp\NewConfig.inf'

# Export the current configuration
secedit /export /cfg $ExportFile

# Find the current list of SIDs having already this right
$CurrentServiceLogonRight = Get-Content -Path $ExportFile | Where-Object -FilterScript {$PSItem -match 'SeServiceLogonRight'}

# Create a new configuration file and add the new SID
$FileContent = @'
[Unicode]
Unicode=yes
[System Access]
[Event Audit]
[Registry Values]
[Version]
signature="$CHICAGO$"
Revision=1
[Profile Description]
Description=GrantLogOnAsAService security template
[Privilege Rights]
{0}*{1}
'@ -f $(
        if($CurrentServiceLogonRight){"$CurrentServiceLogonRight,"}
        else{'SeServiceLogonRight = '}
    ), $AccountSid

Set-Content -Path $ImportFile -Value $FileContent

# Import the new configuration 
secedit /import /db $SecDb /cfg $ImportFile
secedit /configure /db $SecDb

# Change userid of the service
# ----------------------------

$UserName = $DomainAdminID
$Password = $DomainAdminPwd
$Service  = "AmazonSSMAgent"

$ServiceObject = Get-WmiObject win32_service -filter "name='$Service'"

$StopStatus = $ServiceObject.StopService() 
If ($StopStatus.ReturnValue -eq "0") { # validating status - http://msdn.microsoft.com/en-us/library/aa393673(v=vs.85).aspx 
    Write-Output "$ServerN -> Service Stopped Successfully"
} 

$ChangeStatus = $ServiceObject.change($null,$null,$null,$null,$null,$null,$UserName,$Password,$null,$null,$null) 
If ($ChangeStatus.ReturnValue -eq "0") {
    Write-Output "$ServerN -> Sucessfully Changed User Name"
} 

$StartStatus = $ServiceObject.StartService() 
If ($StartStatus.ReturnValue -eq "0") {
    Write-Output "$ServerN -> Service Started Successfully"
}
