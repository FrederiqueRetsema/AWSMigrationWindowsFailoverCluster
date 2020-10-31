# Copy-ToS3.ps1
# -------------
# Example: Copy-ToS3 -FromDir D:\Zips -S3BucketName fra-euwest-1

param([Parameter(Mandatory=$true)][String] $FromDir,
      [Parameter(Mandatory=$true)][String] $S3BucketName) 

Get-ChildItem $FromDir -Filter *.zip | `
  Foreach-Object {
    $FullPathZipFile = $_.FullName
    $ZipFile         = $_.BaseName + ".zip"
    $S3TargetDir     = "s3://" + $S3BucketName + "/"

    aws s3 cp $FullPathZipFile $S3TargetDir
    aws s3api put-object-acl --bucket $S3BucketName --key $ZipFile --acl public-read
  }
