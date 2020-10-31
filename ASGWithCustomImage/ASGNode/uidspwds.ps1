# uidspwds.ps1
# ============

set-alias -Name aws -Value "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
$PasswordParameter = aws ssm get-parameter --name /demo/failover/password --with-decryption |ConvertFrom-Json
$LocalAdminID      = "Administrator"
$LocalAdminPwd     = $PasswordParameter.Parameter.Value

