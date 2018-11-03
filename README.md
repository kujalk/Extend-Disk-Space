# Extend-Disk-Space
Increasing and Extending the disk space of Windows 2012/2016 VMs running in VMWare through remote Powershell script

Below steps explain the script in detail,

1)Getting the VM List

$vmlist=Read-Host "Give the location of VM List File Eg-[D:\vm.txt]"

$list=get-content $source

2)Filtering the powered ON VMs only
$more_data=get-vm $vm
$power = $more_data | select PowerState -ExpandProperty PowerState
if($power -eq "PoweredOff")
{
......
}
else
{
......
}

3)Get the capacity of the 1st Hard Disk (C:\) attached to VM
[int]$nn=Get-Harddisk $vm | select CapacityGB -ExpandProperty CapacityGB -first 1
4)Summing up existing C:\ drive with additional wanted capacity
[int]$Total=$Existing+$Wanted
5)Getting the name of data store of the VM
$NDatastore=Get-VM $vm | Get-datastore | select Name -ExpandProperty Name
6)Check the free space on data store (Minimum 50 GB Free space is ensured after the expansion in the data store)
$FDatastore = Get-VM $vm | Get-datastore | select FreeSpaceGB -ExpandProperty FreeSpaceGB
[int]$check=50+$Wanted
If ($check -lt $FDatastore)
{
Set-HardDisk -HardDisk $HD -capacityGB $ss -confirm:$false
}
else
{
timestamp "<<Error>> Free space on $NDatastore is not enough to increase the         disk capacity of $VM_name"
}
7)If all the above process are successful, expand the disk space with in OS
#Setting the execution policy in the VM
Invoke-VMScript -VM $vm -ScriptText 'set-executionpolicy bypass' -GuestUser $UserVM -GuestPassword $PasswordVM -ScriptType PowerShell
#Extending the disk space inside the OS
Invoke-VMScript -VM $vm -ScriptText 'Update-Disk -Number 0;$m=(Get-PartitionSupportedSize -DriveLetter c).sizeMax;Resize-Partition -DriveLetter c -Size $m' -GuestUser $UserVM -GuestPassword $PasswordVM -ScriptType PowerShell
