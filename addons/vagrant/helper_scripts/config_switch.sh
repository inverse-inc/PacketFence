#!/bin/bash
set -o nounset -o pipefail -o errexit
mgmt_ip=$1
mgmt_netmask=$2
inline_ip=$3
inline_netmask=$4
inline_l3_ip=$5
inline_l3_netmask=$6

declare -p mgmt_ip mgmt_netmask
declare -p inline_ip inline_netmask
declare -p inline_l3_ip inline_l3_netmask

echo "#################################"
echo "  Running Switch Post Config (config_switch.sh)"
echo "#################################"
sudo su

# Config for OOB Switch

# Warning: bridge and sub bridge interfaces will inherit MAC address
# from *first* port in bridge.
# Consequently, swp48 is used here to make DHCP lease obtained from libvirt
# still working after interfaces remap and reboot.
cat <<EOT > /etc/network/interfaces
auto lo
iface lo inet loopback

auto bridge
iface bridge
    bridge-vlan-aware yes
    bridge-ports swp48 swp1 swp2 swp3 swp6 swp11 swp12 swp13 swp14 swp15 swp16
    bridge-vids 2 3 6 17 18 100
    bridge-pvid 1

auto swp1
iface swp1
    bridge-access 17

auto swp2
iface swp2
    bridge-access 2

auto swp3
iface swp3
    bridge-access 3

auto swp6
iface swp6
    bridge-access 6

auto swp11
iface swp11
    bridge-access 17

auto swp13
iface swp13
    bridge-access 6

auto swp14
iface swp14
    bridge-access 17

auto swp15
iface swp15
    bridge-access 18

auto swp48
iface swp48
    bridge-access 100

auto bridge.6
iface bridge.6
    alias Inline-L2
    address ${inline_ip}
    netmask ${inline_netmask}

auto bridge.17
iface bridge.17
    alias Management
    address ${mgmt_ip}
    netmask ${mgmt_netmask}

auto bridge.18
iface bridge.18
    alias Inline-L3
    address ${inline_l3_ip}
    netmask ${inline_l3_netmask}

auto bridge.100
iface bridge.100 inet dhcp
    alias Internet (used by Vagrant)
    
EOT

echo "#################################"
echo "   Finished"
echo "#################################"
