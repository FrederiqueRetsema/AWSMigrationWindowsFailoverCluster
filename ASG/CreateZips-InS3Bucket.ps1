# CreateZips-InS3Bucket.ps1
# =========================

$SourceDirectory = "D:\Clone\AMIS-unpublished\AWSMigrationWindowsFailoverCluster\ASG\LambdaFunctions"
$ZipDirectory    = "D:\Clone\AMIS-unpublished\AWSMigrationWindowsFailoverCluster\ASG\LambdaFunctions\Zip"
$TempDirectory   = "D:\Temp"
$S3BucketName    = "fra-euwest1"

$7ZipPath        = "C:\Program Files\7-Zip\7z.exe"

Set-Alias -Name 7z -Value $7ZipPath
. $SourceDirectory\CreateZips-FromPys.ps1 -SourceDirectory $SourceDirectory -ZipDirectory $ZipDirectory -TempDirectory $TempDirectory
. $SourceDirectory\CopyZips-ToS3.ps1 -FromDir $ZipDirectory -S3BucketName $S3BucketName
