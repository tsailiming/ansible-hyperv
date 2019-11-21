#!powershell

# WANT_JSON
# POWERSHELL_COMMON

#Requires -Module Ansible.ModuleUtils.Legacy

Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

$parsed_args = Parse-Args $args $true

$result = @{changed=$false}

$server_name = Get-AnsibleParam $parsed_args "server_name" -default "(local)"
$db_name = Get-AnsibleParam $parsed_args "db_name" -failifempty $result
$state = Get-AnsibleParam $parsed_args "state" -default "present" -ValidateSet @("present","absent")
$check_mode = Get-AnsibleParam $parsed_args "_ansible_check_mode" -default $false

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null

$server = New-Object Microsoft.SqlServer.Management.Smo.Server $server_name

$db = $server.Databases[$db_name]

If(-not $db -and $state -eq "present") {
    $result.changed = $true

    If(-not $check_mode) {
        # DB doesn't exist, create it
        $db = New-Object Microsoft.SqlServer.Management.Smo.Database @($server, $db_name)
        $db.Create()
    }
}
ElseIf($db -and $state -eq "absent") {
    $result.changed = $true

    If(-not $check_mode) {
        $db.Drop()
    }
}

return $result | ConvertTo-Json -Depth 99

