set -x

if [[ $1 == 'create' ]]; then
    NET_ID=$(openstack network create fsf-mgmt-net --provider-physical-network fsf-net --provider-network-type vlan | grep '| id ' | awk '{print $4}')
    openstack subnet pool create fsf-mgmt-subnet-pool --pool-prefix 172.19.32.0/20 --default-prefix-length 20
    openstack subnet create fsf-mgmt-subnet --ip-version 4 --subnet-pool fsf-mgmt-subnet-pool --network fsf-mgmt-net --no-dhcp
    PORT_ID=$(openstack port create mgmt --disable-port-security --fixed-ip subnet=fsf-mgmt-subnet,ip-address=172.19.32.3 --network fsf-mgmt-net | grep '| id ' | awk '{print $4}')

    sudo ip link add pic${PORT_ID:0:11} type veth peer name tap${PORT_ID:0:11}
    openstack port set --binding-profile provisioning-fsf=true --host $(hostname) ${PORT_ID}

    MAC_ADDRESS=$(openstack port show mgmt | grep '| mac_address ' | awk '{print $4}')
    sudo ip link set pic${PORT_ID:0:11} address $MAC_ADDRESS

	sudo ip link set pic${PORT_ID:0:11} up
    sudo ip add add 172.19.32.3/20 dev pic${PORT_ID:0:11}
elif [[ $1 == 'delete' ]]; then
    PORT_ID=$(openstack port show mgmt | grep '| id ' | awk '{print $4}')
    sudo ip link delete pic${PORT_ID:0:11}
    openstack port delete mgmt
    openstack subnet delete fsf-mgmt-subnet
    openstack subnet pool delete  fsf-mgmt-subnet-pool
    openstack network delete fsf-mgmt-net
fi
