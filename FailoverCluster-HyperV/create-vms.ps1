# Create the Hyper-V VMs for the demo of Failover Clusters
# --------------------------------------------------------
# 
# Will create the (five) Hyper-V VMs for the demo of failover clusters on this Hyper-V computer.
# It will -not- configure the VMs. See the blog for more information about configuring the VMs.
#
# The VMs will use the first "Internal" switch that is present on this computer. If you didn't use an internal network
# before, open Hyper-V Manager > Virtual Switch Manager and create an internal switch (default parameters will do). 
#
# This script requires administrator permissions to run.
#
# Parameters:
# - BaseDir: Basedir for virtual machines. The virtual machines will be created in (five) subdirectories under this directory. 
# - ISOFile: Full path to the ISO file for Windows Server. I used Windows Server 2019, but it might work on older versions as well.
# - VLanNumberPublic: VLAN number for the public network (i.e: network with DC, Demo and cluster nodes)
# - VLanNumberPrivate: VLAN number for the private network (i.e: network for cluster nodes only)
# - Prefix: Prefix for VM names. F.e: prefix = Demo- will create the VMs Demo-DC, Demo-ClusterNode1, etc. Is not mandatory.
# 
# Examples:
#
# & .\create-vms.ps1 -Basedir D:\VMs -ISOFile D:\Install\MSDN\en_windows_server_2019_updated_sep_2020_x64_dvd_2d6f25f2.iso -VLanNumberPublic 10 -VlanNumberPrivate 11 
#
# Will create the VM's with the names DC, ClusterNode1, ClusterNode2, ClusterNode3, Demo. The files will be put in the directory D:\VMs\DC, D:\VMs\ClusterNode1, etc.
# A DVD will be added to the VM, with the ISO-file D:\Install\MSDN\en_windows_server_2019_updated_sep_2020_x64_dvd_2d6f25f2.iso . The DC and the Demo VM will be attached
# to VLan number 10, the ClusterNodes will be attached to both VLan 10 and VLan 11. 
#
# & .\create-vms.ps1 -Basedir D:\VMs -ISOFile D:\Install\MSDN\en_windows_server_2019_updated_sep_2020_x64_dvd_2d6f25f2.iso -VLanNumberPublic 10 -VlanNumberPrivate 11 -Prefix AMISBlog-
#
# Same as before, but the names of the VM's and directories will be AMISBlog-DC, AMISBlog-ClusterNode1, etc.
#
# Based on my blog on https://technology.amis.nl

param([Parameter(Mandatory=$true)] [String] $BaseDir,
      [Parameter(Mandatory=$true)] [String] $ISOFile,
      [Parameter(Mandatory=$true)] [Int]    $VLanNumberPublic,
      [Parameter(Mandatory=$true)] [Int]    $VlanNumberPrivate,
                                   [String] $Prefix)

# Create-VM
# ---------
# Will create a VM with one network card. 

function Create-VM {

  param ([String] $VMName,
         [String] $BaseDir,
         [String] $ISOFile,
         [String] $SwitchName,
         [Int]    $VLanNumber) 

  $GENERATION        = 2
  $STARTUP_MEMORY_MB = 2048 * 1024 * 1024
  $DYNAMIC_MEMORY    = $true
  $NUMBER_OF_CPUS    = 2
  $DISKSIZE_GB       = 127 * 1024 * 1024 * 1024
  $BOOTDEVICE        = "CD"

  $VHDPath           = "${BaseDir}\${VMName}\${VMName}.vhdx"

  New-VHD -Path $VHDPath -SizeBytes $DISKSIZE_GB -Dynamic

  New-VM -Name               $VMName                `
         -MemoryStartupBytes "${STARTUP_MEMORY_MB}" `
         -Path               $BaseDir               `
         -Generation         $GENERATION            `
         -BootDevice         $BOOTDEVICE

  Set-VMProcessor      -VMName $VMName -Count $NUMBER_OF_CPUS

  Set-VMMemory         -VMName $VMName -DynamicMemoryEnabled $DYNAMIC_MEMORY

  Add-VMScsiController -VMName $VMName
  Add-VMHardDiskDrive  -VMName $VMName -ControllerNumber 0 -Path $VHDPath
  Set-VMDvdDrive       -VMName $VMName -Path $ISOFile

  Get-VMNetworkAdapter -VMName $VMName | Connect-VMNetworkAdapter -SwitchName $SwitchName 
  Get-VMNetworkAdapter -VMName $VMName | Set-VMNetworkAdapterVlan -VlanId $VLanNumber -Access
}

# Get-FirstInternalSwitchName
# ---------------------------
function Get-FirstInternalSwitchName {

  $FirstInternalSwitch = Get-VMSwitch | Where-Object SwitchType -EQ "Internal"

  if (($FirstInternalSwitch  | Measure-Object).Count -GT 0) {

    $FirstInternalSwitch     = $FirstInternalSwitch[0]
    $FirstInternalSwitchName = ($FirstInternalSwitch).Name

  } else {

    Write-Error -Message "No internal switch on this machine, please add an internal switch in Hyper-V"
    exit 1

  }

  return $FirstInternalSwitchName
}

# Add-NetworkCard
# ---------------
function Add-NetworkCard {
  param ([String] $VMName,
         [String] $SwitchName,
         [Int]    $VlanNumber) 

  Add-VMNetworkAdapter -VMName "${VMName}" `
                       -SwitchName "${SwitchName}" -Passthru | Set-VMNetworkAdapterVlan -VlanId $VLanNumber -Access

}

# Main Program
# ------------

$FirstInternalSwitchName = Get-FirstInternalSwitchName
Create-VM       -VMName "${Prefix}DC"            -BaseDir $BaseDir -ISOFile $ISOFile -SwitchName "${FirstInternalSwitchName}" -VLanNumber $VLanNumberPublic 

Create-VM       -VMName "${Prefix}ClusterNode1"  -BaseDir $BaseDir -ISOFile $ISOFile -SwitchName "${FirstInternalSwitchName}" -VLanNumber $VLanNumberPublic 
Add-NetworkCard -VMName "${Prefix}ClusterNode1"                                      -SwitchName "${FirstInternalSwitchName}" -VlanNumber $VlanNumberPrivate

Create-VM       -VMName "${Prefix}ClusterNode2"  -BaseDir $BaseDir -ISOFile $ISOFile -SwitchName "${FirstInternalSwitchName}" -VLanNumber $VLanNumberPublic 
Add-NetworkCard -VMName "${Prefix}ClusterNode2"                                      -SwitchName "${FirstInternalSwitchName}" -VlanNumber $VlanNumberPrivate

Create-VM       -VMName "${Prefix}ClusterNode3"  -BaseDir $BaseDir -ISOFile $ISOFile -SwitchName "${FirstInternalSwitchName}" -VLanNumber $VLanNumberPublic 
Add-NetworkCard -VMName "${Prefix}ClusterNode3"                                      -SwitchName "${FirstInternalSwitchName}" -VlanNumber $VlanNumberPrivate

Create-VM       -VMName "${Prefix}Demo"          -BaseDir $BaseDir -ISOFile $ISOFile -SwitchName "${FirstInternalSwitchName}" -VLanNumber $VLanNumberPublic 
