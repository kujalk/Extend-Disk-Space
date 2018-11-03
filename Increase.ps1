#Developer - Janarthanan Kugathasan
#Version - 1
#Purpose - To extend the disk space of 2012 and 2016 VMs
#Date - 1/11/2018

<#
Steps---
1) Open the PowerCLI as different user (priviledge user) and Execute this script
2) Guest User is a the priviledge user password
#>


Write-host "
1) Open the PowerCLI as different user (priviledge user) and Execute this script
2) Guest User is a the priviledge user password
"

#function for logging time
function timestamp ($message)
{
$date=Get-Date
"$date : $message" >> $log
}


$vCenter= Read-Host -Prompt "Please enter the Vcenter you want to connect `n" 

$vCenterUser= Read-Host -Prompt "Enter user name (Domain\xxxxx) `n"

$vCenterUserPassword= Read-Host -Prompt "Password `n" -assecurestring

$credential = New-Object System.Management.Automation.PSCredential($vCenterUser,$vCenterUserPassword)

Connect-VIServer -Server $vCenter -Credential $credential

#To avoid timeout
Set-PowerCLIConfiguration -WebOperationTimeoutSeconds -1 -confirm:$false

$UserVM = $vCenterUser
$PasswordVM= Read-Host -Prompt " Guest Password for VM `n"

cls

[int]$pp=Read-host "Please give how much (extra) disk capacity you need in GB :"

$folder_loc=Read-Host "Give a folder location to store log and related files Eg-[D:\Log]"
$vmlist=Read-Host "Give the location of VM List File Eg-[D:\vm.txt]"

#Required Files
$power_off= "$folder_loc"+"\powered_off_VMs.txt"
$log="$folder_loc"+"\vm_log.txt"
$success="$folder_loc"+"\vm_success.txt"
$failed_vm="$folder_loc"+"\vm_failed.txt"


$list=get-content $vmlist

foreach($vm in $list)
{
timestamp "`n Started Working on $vm"

$more_data=get-vm $vm
$power = $more_data | select PowerState -ExpandProperty PowerState
$guest_status=$more_data.ExtensionData.Guest.ToolsRunningStatus
timestamp "VMWare Tools Status in $vm : $guest_status"


		if($power -eq "PoweredOff")
		{
		timestamp "$vm is powered off"
		"$vm" >> $power_off
		}
		

		
		else
		{
			#Only for C:\ drive
			[int]$nn=Get-Harddisk $vm | select CapacityGB -ExpandProperty CapacityGB -first 1

			#Summing up existing C:\ drive with additional wanted capacity
			[int]$ss=$nn+$pp

			#To get HD capacity allocated to that VM from VMware side
			$HD=Get-HardDisk -VM $vm | select -first 1


            #Getting the name of datastore of the VM
            $NDatastore=Get-VM $vm | Get-datastore | select Name -ExpandProperty Name

            #Getting the free space of datastore
            $FDatastore = Get-VM $vm | Get-datastore | select FreeSpaceGB -ExpandProperty FreeSpaceGB

            [int]$check=50+$pp

				If ($check -lt $FDatastore)
				{
					#To increase the space of HD from VMware side (specify the final value in GB)
					Set-HardDisk -HardDisk $HD -capacityGB $ss -confirm:$false
					timestamp "<<Info>> Hard disk was expanded in VMware side"
					[int]$need_chk=1
				}

				else
				{
					timestamp "<<Error>> Free space on $NDatastore is not enough to increase the disk capacity of $vm"
				}
		
		
			#Part-2
		
		   if ($need_chk -eq 1)
		   {
			#Setting the execution policy in the VM
			Invoke-VMScript -VM $vm -ScriptText 'set-executionpolicy bypass' -GuestUser $UserVM  -GuestPassword $PasswordVM -ScriptType PowerShell
			
			#Extending the disk space inside the OS
			Invoke-VMScript -VM $vm -ScriptText 'Update-Disk -Number 0;$m=(Get-PartitionSupportedSize -DriveLetter c).sizeMax;Resize-Partition -DriveLetter c -Size $m' -GuestUser $UserVM  -GuestPassword $PasswordVM -ScriptType PowerShell
			
			#To check whether reconfiguration is successful
			if($? -eq "True")
			{
				timestamp "$vm is successfull"
				"$vm" >> $success
			}
			
			else
			{
				timestamp "$vm is failed"
				"$vm" >> $failed_vm
			}
			
			}
			
		}
		
		"`n" >> $log

}

#Disconnecting from Vcenter	
Disconnect-VIServer -Server $vCenter -confirm:$false
timestamp "Disconnected from datacenter. Bye !!! Bye !!!"

