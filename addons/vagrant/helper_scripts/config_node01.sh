#!/bin/bash
set -o nounset -o pipefail -o errexit
mgmt_ip=$1
mgmt_netmask=$2
mgmt_ipv6=$3
mgmt_prefix=$4

declare -p mgmt_ip mgmt_netmask mgmt_ipv6 mgmt_prefix

echo "#################################"
echo "  Running config_node01.sh"
echo "#################################"
sudo su

#Replace existing network interfaces file
echo -e "auto lo" > /etc/network/interfaces
echo -e "iface lo inet loopback\n\n" >> /etc/network/interfaces

#Add vagrant interface
echo -e "\n\nauto eth0" >> /etc/network/interfaces
echo -e "iface eth0 inet dhcp\n\n" >> /etc/network/interfaces

# Make DHCP Try Over and Over Again
echo "retry 1;" >> /etc/dhcp/dhclient.conf

# Other stuff
ping 8.8.8.8 -c2
if [ "$?" == "0" ]; then
    apt-get update -qy && apt-get install gnupg -qy
    apt-get install lldpd unzip curl -qy
    echo "configure lldp portidsubtype ifname" > /etc/lldpd.d/port_info.conf

fi

# Set Timezone
cat << EOT > /etc/timezone
Etc/UTC
EOT

# Once initial provisioning is done, we apply new network configuration
# Internet connection is lost, only management using VLAN17 is possible
echo " ### Overwriting /etc/network/interfaces ###"
cat <<EOT > /etc/network/interfaces
auto lo
iface lo inet loopback

auto ens6
iface ens6 inet static
    alias VLAN 17
    address ${mgmt_ip}
    netmask ${mgmt_netmask}

iface ens6 inet6 static
    alias VLAN 17 IPv6
    address ${mgmt_ipv6}/${mgmt_prefix}

allow-hotplug ens7
iface ens7 inet dhcp
    alias dot1x port

allow-hotplug ens8
iface ens8 inet dhcp
    alias inline port

EOT

echo "#################################"
echo "   Finished"
echo "#################################"
