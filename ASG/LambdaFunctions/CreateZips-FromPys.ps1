# Create-ZipFromPys.ps1
# ---------------------
# Example: CreateZips-FromPys.ps1 -SourceDirectory D:\Clone\AMIS-unpublished\AWSMigration\FailoverCluster\LambdaFunctions -ZipDirectory D:\Zips -TempDirectory D:\Temp

param([Parameter(Mandatory=$true)][String] $SourceDirectory,
      [Parameter(Mandatory=$true)][String] $ZipDirectory,
      [Parameter(Mandatory=$true)][String] $TempDirectory)

# Create-ZipFileWithoutLibrary
# ----------------------------
function Create-ZipFileWithoutLibrary {
  param([String] $PythonFile,
        [String] $ZipFile)

  7z a $ZipFile $PythonFile
}

# Create-ZipFileWithLibraries
# ---------------------------
function Create-ZipFileWithLibrary {
  param([String] $PythonFile,
        [String] $ZipFile,
        [String] $Library,
        [String] $TempDirectory)

  $FromDirectory = Get-Location

  Set-Location $TempDirectory
  Remove-Item -Path *.* -Recurse:$True -Confirm:$False

  New-Item -Name Venv -Confirm:$False -ItemType "directory"
  python -m venv .\Venv

  Set-Location .\venv\Scripts\ 
  & .\activate
  Set-Location ..\..
  pip install ${library} -t .
  Deactivate

  Set-Location $TempDirectory
  Remove-Item -Path Venv -Confirm:$false -Recurse
  Copy-Item $PythonFile .

  if (Test-Path $ZipFile) {
    Remove-Item -Path $ZipFile -Confirm:$False
  }   
  7z a -r $ZipFile *

  Set-Location $FromDirectory
}

# Main Program 
# ============

if (!(Test-Path $TEMPDIRECTORY -PathType Container)) {
  New-Item -Path $TEMPDIRECTORY -ItemType "directory"
}
if (!(Test-Path $ZIPDIRECTORY -PathType Container)) {
  New-Item -Path $ZIPDIRECTORY -ItemType "directory"
}

Create-ZipFileWithLibrary    -PythonFile "${SourceDirectory}\PutSecureParameter.py"            -ZipFile "${ZIPDIRECTORY}\PutSecureParameter.zip"      -Library requests -TempDirectory $TEMPDIRECTORY
Create-ZipFileWithLibrary    -PythonFile "${SourceDirectory}\UpdateASGConfiguration.py"        -ZipFile "${ZIPDIRECTORY}\UpdateASGConfiguration.zip"  -Library requests -TempDirectory $TEMPDIRECTORY
Create-ZipFileWithoutLibrary -PythonFile "${SourceDirectory}\CreateOrDeletePowershellEvent.py" -ZipFile "${ZIPDIRECTORY}\CreateOrDeletePowershellEvent.zip"
Create-ZipFileWithoutLibrary -PythonFile "${SourceDirectory}\StartPowershellEvent.py"          -ZipFile "${ZIPDIRECTORY}\StartPowershellEvent.zip"

Remove-Item -Path $TEMPDIRECTORY -Recurse:$True -Confirm:$False
