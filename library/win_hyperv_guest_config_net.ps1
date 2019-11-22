#!powershell
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# WANT_JSON
# POWERSHELL_COMMON

#Requires -Module Ansible.ModuleUtils.Legacy

$params = Parse-Args $args;
$result = @{};
Set-Attr $result "changed" $false;

$name = Get-Attr -obj $params -name name -failifempty $true -emptyattributefailmessage "missing required argument: name"
$ip = Get-Attr -obj $params -name ip
$netmask = Get-Attr -obj $params -name netmask
$gateway = Get-Attr -obj $params -name gateway
$dns = Get-Attr -obj $params -name dns
$type = Get-Attr -obj $params -name type -default 'dhcp'

if ("static", "dhcp" -notcontains $type) {
  Fail-Json $result "The type: $type doesn't exist; Type can only be: static, dhcp"
}

# http://www.ravichaganti.com/blog/set-or-inject-guest-network-configuration-from-hyper-v-host-windows-server-2012/
Function Set-VMNetworkConfiguration {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory=$true,
     Position=1,
     ParameterSetName='DHCP',
     ValueFromPipeline=$true)]
    [Parameter(Mandatory=$true,
     Position=0,
     ParameterSetName='Static',
     ValueFromPipeline=$true)]
    [Microsoft.HyperV.PowerShell.VMNetworkAdapter]$NetworkAdapter,
    
    [Parameter(Mandatory=$true,
     Position=1,
     ParameterSetName='Static')]
    [String[]]$IPAddress=@(),
    
    [Parameter(Mandatory=$false,
     Position=2,
     ParameterSetName='Static')]
    [String[]]$Subnet=@(),
    
    [Parameter(Mandatory=$false,
     Position=3,
     ParameterSetName='Static')]
    [String[]]$DefaultGateway = @(),
    
    [Parameter(Mandatory=$false,
     Position=4,
     ParameterSetName='Static')]
    [String[]]$DNSServer = @(),
    
    [Parameter(Mandatory=$false,
     Position=0,
     ParameterSetName='DHCP')]
    [Switch]$Dhcp
    )
  
  $VM = Get-WmiObject -Namespace 'root\virtualization\v2' -Class 'Msvm_ComputerSystem' | Where-Object { $_.ElementName -eq $NetworkAdapter.VMName } 
  $VMSettings = $vm.GetRelated('Msvm_VirtualSystemSettingData') | Where-Object { $_.VirtualSystemType -eq 'Microsoft:Hyper-V:System:Realized' }    
  $VMNetAdapters = $VMSettings.GetRelated('Msvm_SyntheticEthernetPortSettingData') 
  
  $NetworkSettings = @()
  foreach ($NetAdapter in $VMNetAdapters) {
    if ($NetAdapter.Address -eq $NetworkAdapter.MacAddress) {
      $NetworkSettings = $NetworkSettings + $NetAdapter.GetRelated("Msvm_GuestNetworkAdapterConfiguration")
    }
  }
  
  $NetworkSettings[0].IPAddresses = $IPAddress
  $NetworkSettings[0].Subnets = $Subnet
  $NetworkSettings[0].DefaultGateways = $DefaultGateway
  $NetworkSettings[0].DNSServers = $DNSServer
  $NetworkSettings[0].ProtocolIFType = 4096
  
  if ($dhcp) {
    $NetworkSettings[0].DHCPEnabled = $true
    } else {
      $NetworkSettings[0].DHCPEnabled = $false
    }
    
    $Service = Get-WmiObject -Class "Msvm_VirtualSystemManagementService" -Namespace "root\virtualization\v2"
    $setIP = $Service.SetGuestNetworkAdapterConfiguration($VM, $NetworkSettings[0].GetText(1))
    
    if ($setip.ReturnValue -eq 4096) {
      $job=[WMI]$setip.job 
      
      while ($job.JobState -eq 3 -or $job.JobState -eq 4) {
        start-sleep 1
        $job=[WMI]$setip.job
      }
      
      if ($job.JobState -eq 7) {
        write-host "Success"
      }
      else {
        $job.GetError()
      }
      } elseif($setip.ReturnValue -eq 0) {
        Write-Host "Success"
      }
    }

    Try {
      $CheckVM = Get-VM -name $name -ErrorAction SilentlyContinue

      if ($CheckVM) {
        $cmd = "Get-VMNetworkAdapter -VMName $name | "
        
        if ($type -eq 'dhcp' ) {
          $cmd += "Set-VMNetworkConfiguration -DHCP" 
        }

        else {
          $cmd += "Set-VMNetworkConfiguration -IPAddress $ip -Subnet $netmask -DNSServer $dns -DefaultGateway $gateway"
        }

        invoke-expression $cmd
        $result.new =  $cmd
        $result.changed = $true
        } else {
          $result.changed = $false
        }
        Exit-Json $result;

        } Catch {
          Fail-Json $result $_.Exception.Message
        }
