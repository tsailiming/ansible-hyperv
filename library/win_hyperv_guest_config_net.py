#!/usr/bin/python
# -*- coding: utf-8 -*-

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

# this is a windows documentation stub. actual code lives in the .ps1
# file of the same name

DOCUMENTATION = '''
---
module: win_hyperv_config_net
version_added: "2.4"
short_description: Configure Hyper-V VM's network.
description:
    - Configure Hyper-V VM's network.
options:
  name:
    description:
      - Name of VM
    required: true
  ip: 
    description:
      - IP Address
    required: false
    default: null
  netmask:
    description:
      - Netmask
    required: false
    default: null
  gateway:
    description:
      - Gateway
    required: false
    default: null
  dns: 
    description:
      - DNS
    required: false
    default: null
  type:
    description:
      - Whether is static or dhcp
    required: true
    default: dhcp

'''

EXAMPLES = '''

'''

ANSIBLE_METADATA = {
    'status': ['preview'],
    'supported_by': 'community',
    'metadata_version': '1.1'
}
