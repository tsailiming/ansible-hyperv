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
$cpu = Get-Attr -obj $params -name cpu -default '1'
$memory = Get-Attr -obj $params -name memory -default '512MB'
$hostserver = Get-Attr -obj $params -name hostserver
$generation = Get-Attr -obj $params -name generation -default 2
$network_switch = Get-Attr -obj $params -name network_switch -default $null

$diskpath = Get-Attr -obj $params -name diskpath -default $null

$showlog = Get-Attr -obj $params -name showlog -default "false" | ConvertTo-Bool
$state = Get-Attr -obj $params -name state -default "present"

if ("poweroff", "present","absent","started","stopped" -notcontains $state) {
  Fail-Json $result "The state: $state doesn't exist; State can only be: present, absent, started or stopped"
}

Function VM-Create {
  #Check If the VM already exists
  $CheckVM = Get-VM -name $name -ErrorAction SilentlyContinue

  if (!$CheckVM) {
    $cmd = "New-VM -Name $name"

    if ($memory) {
      $cmd += " -MemoryStartupBytes $memory"
    }

    if ($hostserver) {
      $cmd += " -ComputerName $hostserver"
    }

    if ($generation) {
      $cmd += " -Generation $generation"
    }

    if ($network_switch) {
      $cmd += " -SwitchName '$network_switch'"
    }

    if ($diskpath) {
      #If VHD already exists then attach it, if not create it
      if (Test-Path $diskpath) {
        $cmd += " -VHDPath '$diskpath'"
        } else {
          $cmd += " -NewVHDPath '$diskpath'"
        }
      }

      # Need to chain these
      $results = invoke-expression $cmd
      $results = invoke-expression "Set-VMProcessor $name -Count $cpu"

      $result.changed = $true
      } else {
        $result.changed = $false
      }
    }

    Function VM-Delete {
      $CheckVM = Get-VM -name $name -ErrorAction SilentlyContinue

      if ($CheckVM) {
        $cmd="Remove-VM -Name $name -Force"
        $results = invoke-expression $cmd
        $result.changed = $true
        } else {
         $result.changed = $false
       }
     }

     Function VM-Start {
      $CheckVM = Get-VM -name $name -ErrorAction SilentlyContinue

      if ($CheckVM) {
        $cmd="Start-VM -Name $name"
        $results = invoke-expression $cmd
        $result.changed = $true
        } else {
         Fail-Json $result "The VM: $name; Doesn't exists please create the VM first"
       }
     }

     Function VM-Poweroff {
      $CheckVM = Get-VM -name $name -ErrorAction SilentlyContinue

      if ($CheckVM) {
        $cmd="Stop-VM -Name $name -TurnOff"
        $results = invoke-expression $cmd
        $result.changed = $true
        } else {
         Fail-Json $result "The VM: $name; Doesn't exists please create the VM first"
       }
     }

     Function VM-Shutdown {
      $CheckVM = Get-VM -name $name -ErrorAction SilentlyContinue

      if ($CheckVM) {
        $cmd="Stop-VM -Name $name"
        $results = invoke-expression $cmd
        $result.changed = $true
        } else {
         Fail-Json $result "The VM: $name; Doesn't exists please create the VM first"
       }
     }

     Try {
      switch ($state) {
        "present" {VM-Create}
        "absent" {VM-Delete}
        "started" {VM-Start}
        "stopped" {VM-Shutdown}
        "poweroff" {VM-Poweroff}
      }

      Exit-Json $result;
      } Catch {
        Fail-Json $result $_.Exception.Message
      }
