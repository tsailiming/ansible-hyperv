# Introduction

This is heavily inspired by [glenndehaan](https://github.com/glenndehaan/ansible-win_hyperv_guest)'s original code to provision a vm on HyperV.

The code has been modified to provision VMs by:
* Cloning a disk
* Setting up the IP 
* Powering on the VM
* Wait for WinRM port to be available

The configuration is stored as an environment yaml file, such as `vars/sit.yml`. This is meant to allow the user to define the environments such as DEV/UAT/SIT and its associated network information for each vm.

# Playbook

There is a sample `create_vm.yml` playbook that consists of 3 plays:
* Provision a sit environment with 2 VMS and create the necessary groups: web and db
* Configure static ips
* Runs `web_ping` against the 2 groups: web and db.
