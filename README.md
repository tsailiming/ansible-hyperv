# Introduction

This is heavily inspired by [glenndehaan](https://github.com/glenndehaan/ansible-win_hyperv_guest)'s original code to provision a vm on HyperV.

The code has been modified to provision VMs by:
* Cloning a disk
* Setting up the IP 
* Powering on the VM
* Wait for WinRM port to be available

The configuration is stored as an environment yaml file, such as `vars/sit.yml`. This is meant to allow the user to define the environments such as DEV/UAT/SIT and its associated network information for each vm.

# Requirements

* Win2012R2 vhd image with WinRM enabled. You can use Ansible's [ConfigureRemotingForAnsible.ps1](https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1)
* MS SQL 2014 Express installer. 
* .Net Framework >= 4.0, if you want to run OrchardCMS, inclduding the setup.exe
* OrchardCMS is downloaded from github releases

# Playbooks

## Creation of VM
There is a sample `create_vm.yml` playbook:
* Provision a sit environment with 2 VMS and create the necessary groups: web and db
* Configure static ips
* `wait_for` WinRM is up before exiting

## Building Golden Template

The playbook `build_golden.yml` is use to install the necessary software using roles. After building the image, you can then use the vhd in your environment yaml file.

## Deploying Application

`prov_web_db.yml` is to provision the sample `App_Data` and restore a database from a backup from templates. The roles to install the IIS and MS-SQL have been disabled by default. 

## Deleting the VMs

Use `delete_vm.yml` to delete the vms and clean out the disk.

# Running the playbook

You can change enviornment by either editing the `var/` yaml files or using `-e` option in the command line.

Ansible Tower can also be used by using a survey form.

# Script

There is a `bin/run.ps1` sample script that calls Ansible Tower API to launch the Job Teamplate and monitor the job till it exits.

# Credits

The various roles and PowerShell scripts are adopted from:

* https://github.com/bennojoy/ansible-win-sql2014-express
* https://github.com/glenndehaan/ansible-win_hyperv_guest
* https://github.com/nitzmahone/orchard_cms



